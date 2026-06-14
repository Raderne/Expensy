import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// Lifecycle of a queued write.
enum OutboxStatus {
  /// Waiting to be replayed.
  pending,

  /// Rejected by the server with a non-retryable error (e.g. validation). Kept
  /// for visibility but skipped on subsequent drains so it can't wedge the
  /// queue. Surfaced to the user as a "failed" change.
  failed,
}

OutboxStatus _statusFrom(String? raw) =>
    raw == 'failed' ? OutboxStatus.failed : OutboxStatus.pending;

/// A single durable, replayable mutation. Stores the raw HTTP intent rather
/// than a typed command so the [SyncEngine] can replay any endpoint without
/// per-feature knowledge — the repositories own the request shape.
@immutable
class OutboxEntry {
  /// Stable queue id (also the Hive key).
  final String id;

  /// Wall-clock enqueue time; the queue replays in this order (FIFO).
  final int createdAt;

  /// Coarse classifier (e.g. `txCreate`, `categoryDelete`) — used only for
  /// debugging/telemetry; replay is driven by [method]/[path]/[body].
  final String kind;

  final String method; // POST | PUT | PATCH | DELETE
  final String path; // e.g. /transactions, /categories/<id>
  final Map<String, dynamic>? body;

  /// Stable per-entry key so a duplicated/retried replay is a server-side no-op
  /// within the backend's idempotency window.
  final String idempotencyKey;

  /// For creates: the client-generated placeholder id used by the optimistic UI
  /// row. On successful replay the engine rewrites this id to the server's real
  /// id everywhere it appears in later queued entries.
  final String? tempId;

  final OutboxStatus status;
  final int retryCount;
  final String? lastError;

  const OutboxEntry({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.method,
    required this.path,
    required this.idempotencyKey,
    this.body,
    this.tempId,
    this.status = OutboxStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  OutboxEntry copyWith({
    String? path,
    Map<String, dynamic>? body,
    OutboxStatus? status,
    int? retryCount,
    String? lastError,
    bool clearError = false,
  }) => OutboxEntry(
    id: id,
    createdAt: createdAt,
    kind: kind,
    method: method,
    path: path ?? this.path,
    idempotencyKey: idempotencyKey,
    body: body ?? this.body,
    tempId: tempId,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'kind': kind,
    'method': method,
    'path': path,
    if (body != null) 'body': body,
    'idempotencyKey': idempotencyKey,
    if (tempId != null) 'tempId': tempId,
    'status': status.name,
    'retryCount': retryCount,
    if (lastError != null) 'lastError': lastError,
  };

  factory OutboxEntry.fromJson(Map<String, dynamic> json) => OutboxEntry(
    id: json['id'] as String,
    createdAt: json['createdAt'] as int,
    kind: json['kind'] as String,
    method: json['method'] as String,
    path: json['path'] as String,
    body: (json['body'] as Map?)?.cast<String, dynamic>(),
    idempotencyKey: json['idempotencyKey'] as String,
    tempId: json['tempId'] as String?,
    status: _statusFrom(json['status'] as String?),
    retryCount: (json['retryCount'] as int?) ?? 0,
    lastError: json['lastError'] as String?,
  );
}

/// Durable FIFO queue of pending writes.
abstract class Outbox {
  Future<void> enqueue(OutboxEntry entry);

  /// All entries, oldest first.
  List<OutboxEntry> all();

  Future<void> put(OutboxEntry entry);
  Future<void> remove(String id);
  Future<void> clear();

  int get pendingCount =>
      all().where((e) => e.status == OutboxStatus.pending).length;
  int get failedCount =>
      all().where((e) => e.status == OutboxStatus.failed).length;

  /// Fires whenever the queue contents change, so the status layer can recompute.
  Stream<void> watch();
}

class HiveOutbox implements Outbox {
  HiveOutbox(this._box);

  static const _boxName = 'outbox_v1';
  final Box<String> _box;

  /// Opens the box. Hive itself is already initialized by [HiveHttpCache.open],
  /// which runs first in `main`. Throws if it can't open — callers fall back to
  /// [InMemoryOutbox].
  static Future<HiveOutbox> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return HiveOutbox(box);
  }

  @override
  Future<void> enqueue(OutboxEntry entry) => put(entry);

  @override
  Future<void> put(OutboxEntry entry) =>
      _box.put(entry.id, jsonEncode(entry.toJson()));

  @override
  Future<void> remove(String id) => _box.delete(id);

  @override
  Future<void> clear() => _box.clear();

  @override
  List<OutboxEntry> all() {
    final entries = <OutboxEntry>[];
    for (final raw in _box.values) {
      try {
        entries.add(
          OutboxEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Outbox: dropping corrupt entry: $e');
      }
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  @override
  int get pendingCount =>
      all().where((e) => e.status == OutboxStatus.pending).length;

  @override
  int get failedCount =>
      all().where((e) => e.status == OutboxStatus.failed).length;

  @override
  Stream<void> watch() => _box.watch().map((_) {});
}

/// Fallback when Hive can't initialize (tests, sandboxed environments). Keeps
/// the sync pipeline working in-process, just without persistence across runs.
class InMemoryOutbox implements Outbox {
  final Map<String, OutboxEntry> _store = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Future<void> enqueue(OutboxEntry entry) => put(entry);

  @override
  Future<void> put(OutboxEntry entry) async {
    _store[entry.id] = entry;
    _changes.add(null);
  }

  @override
  Future<void> remove(String id) async {
    _store.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> clear() async {
    _store.clear();
    _changes.add(null);
  }

  @override
  List<OutboxEntry> all() {
    final entries = _store.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  @override
  int get pendingCount =>
      all().where((e) => e.status == OutboxStatus.pending).length;

  @override
  int get failedCount =>
      all().where((e) => e.status == OutboxStatus.failed).length;

  @override
  Stream<void> watch() => _changes.stream;
}

/// Provider for the singleton outbox. Overridden in `main` with the result of
/// [HiveOutbox.open] (or an [InMemoryOutbox] fallback), like [httpCacheProvider].
final outboxProvider = Provider<Outbox>((ref) {
  throw StateError(
    'outboxProvider was not initialized. '
    'Override it in main() with the result of HiveOutbox.open().',
  );
});
