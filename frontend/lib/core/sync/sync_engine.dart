import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../network/dio_client.dart';
import '../network/server_health.dart';
import 'outbox.dart';

@immutable
class SyncEngineState {
  final bool syncing;
  final DateTime? lastSyncedAt;

  const SyncEngineState({this.syncing = false, this.lastSyncedAt});

  SyncEngineState copyWith({bool? syncing, DateTime? lastSyncedAt}) =>
      SyncEngineState(
        syncing: syncing ?? this.syncing,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

/// Drains the [Outbox] against the live API. Every data mutation in the app is
/// written to the outbox first (offline-first), so this is the single place
/// where queued writes actually hit the network.
///
/// Replay rules:
/// - Strict FIFO, so a create is always applied before any later entry that
///   references its id.
/// - Each entry carries a stable `Idempotency-Key`, so replaying a write that
///   secretly already landed (e.g. the response was lost) is a server-side
///   no-op. `404`/`409` are likewise treated as "already applied".
/// - A connection error mid-drain stops the run with order intact; the next
///   trigger resumes from the front.
/// - A `4xx` validation error dead-letters just that entry ([OutboxStatus.failed])
///   and the drain continues, so one bad write can't wedge the queue.
class SyncEngine extends Notifier<SyncEngineState> {
  bool _running = false;

  @override
  SyncEngineState build() => const SyncEngineState();

  Outbox get _outbox => ref.read(outboxProvider);

  /// Attempts to flush the queue. Single-flight: a concurrent call is a no-op.
  /// Safe to call liberally (after each enqueue, on resume, on reconnect).
  Future<void> process() async {
    if (_running) return;
    final outbox = _outbox;
    if (outbox.all().every((e) => e.status == OutboxStatus.failed)) return;

    _running = true;
    state = state.copyWith(syncing: true);
    try {
      if (!await ref.read(connectivityServiceProvider).check()) return;
      if (!await ref.read(serverWakerProvider.notifier).wake()) return;

      final dio = ref.read(dioProvider);
      var madeProgress = false;

      // Re-read the queue head each iteration rather than iterating a snapshot:
      // a successful create rewrites temp ids into later entries, so dependent
      // writes must be read *after* that rewrite to pick up the real id.
      while (true) {
        OutboxEntry? entry;
        for (final e in outbox.all()) {
          if (e.status != OutboxStatus.failed) {
            entry = e;
            break;
          }
        }
        if (entry == null) break;

        final outcome = await _replay(dio, outbox, entry);
        if (outcome == _Outcome.stop) break;
        if (outcome == _Outcome.applied) madeProgress = true;
      }

      if (madeProgress) {
        state = state.copyWith(lastSyncedAt: DateTime.now());
      }
    } finally {
      _running = false;
      state = state.copyWith(syncing: false);
    }
  }

  Future<_Outcome> _replay(Dio dio, Outbox outbox, OutboxEntry entry) async {
    try {
      final res = await dio.request<dynamic>(
        entry.path,
        data: entry.body,
        options: Options(
          method: entry.method,
          headers: {'Idempotency-Key': entry.idempotencyKey},
        ),
      );
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        await _onCreateRemap(outbox, entry, res.data);
        await outbox.remove(entry.id);
        return _Outcome.applied;
      }
      if (status == 404 || status == 409) {
        // Already applied on the server (delete-of-deleted, or a replay the
        // backend deduped). Drop it and move on.
        await outbox.remove(entry.id);
        return _Outcome.applied;
      }
      // Any other 4xx is a permanent rejection (validation/auth). Dead-letter so
      // the user can see it failed without blocking the rest of the queue.
      await outbox.put(
        entry.copyWith(status: OutboxStatus.failed, lastError: 'HTTP $status'),
      );
      return _Outcome.deadLettered;
    } on DioException catch (e) {
      // validateStatus lets <500 through as a response, so reaching here means a
      // connection failure or a 5xx — the server is unavailable. Stop and keep
      // the queue ordered for the next attempt.
      if (kDebugMode) debugPrint('SyncEngine: replay halted: ${e.type}');
      return _Outcome.stop;
    }
  }

  /// After a successful create, rewrite the client temp id to the server's real
  /// id in every still-queued entry that references it (path or body), baking the
  /// mapping into the durable queue so it survives a restart mid-drain.
  Future<void> _onCreateRemap(
    Outbox outbox,
    OutboxEntry entry,
    dynamic responseData,
  ) async {
    final tempId = entry.tempId;
    if (tempId == null) return;
    final realId = _extractId(responseData);
    if (realId == null || realId == tempId) return;

    for (final other in outbox.all()) {
      if (other.id == entry.id) continue;
      final newPath = other.path.contains(tempId)
          ? other.path.replaceAll(tempId, realId)
          : other.path;
      final newBody = _replaceInMap(other.body, tempId, realId);
      if (newPath != other.path || newBody != null) {
        await outbox.put(
          other.copyWith(path: newPath, body: newBody ?? other.body),
        );
      }
    }
  }

  /// Pulls an entity id out of a wrapped response (`{transaction: {id}}`,
  /// `{category: {id}}`, or a bare `{id}`).
  static String? _extractId(dynamic data) {
    if (data is Map) {
      if (data['id'] is String) return data['id'] as String;
      for (final v in data.values) {
        if (v is Map && v['id'] is String) return v['id'] as String;
      }
    }
    return null;
  }

  /// Returns a copy of [body] with any string value equal to [from] swapped to
  /// [to], or `null` if nothing changed.
  static Map<String, dynamic>? _replaceInMap(
    Map<String, dynamic>? body,
    String from,
    String to,
  ) {
    if (body == null) return null;
    var changed = false;
    final copy = <String, dynamic>{};
    body.forEach((k, v) {
      if (v == from) {
        copy[k] = to;
        changed = true;
      } else {
        copy[k] = v;
      }
    });
    return changed ? copy : null;
  }
}

enum _Outcome { applied, deadLettered, stop }

final syncEngineProvider = NotifierProvider<SyncEngine, SyncEngineState>(
  SyncEngine.new,
);
