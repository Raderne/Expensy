import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'outbox.dart';
import 'sync_engine.dart';

/// Write-side façade used by repositories. Every data mutation enqueues here
/// (offline-first) and immediately nudges the [SyncEngine], which drains right
/// away when online or waits for connectivity/wake-up when not.
class OutboxWriter {
  OutboxWriter(this._outbox, this._triggerSync);

  final Outbox _outbox;
  final void Function() _triggerSync;
  static const _uuid = Uuid();

  /// A client-side placeholder id for an optimistic create. Replaced with the
  /// server's real id by the [SyncEngine] once the write lands.
  String newTempId() => 'tmp_${_uuid.v4()}';

  /// Queues a write and kicks a drain. [idempotencyKey] should be stable for a
  /// logical action so replays dedupe server-side; one is generated if omitted.
  Future<void> enqueue({
    required String kind,
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    String? tempId,
  }) async {
    final entry = OutboxEntry(
      id: _uuid.v4(),
      createdAt: DateTime.now().microsecondsSinceEpoch,
      kind: kind,
      method: method,
      path: path,
      body: body,
      idempotencyKey: idempotencyKey ?? _uuid.v4(),
      tempId: tempId,
    );
    await _outbox.enqueue(entry);
    _triggerSync();
  }
}

final outboxWriterProvider = Provider<OutboxWriter>(
  (ref) => OutboxWriter(
    ref.watch(outboxProvider),
    () => unawaited(ref.read(syncEngineProvider.notifier).process()),
  ),
);

/// Reactive view of the queue. Re-emits whenever the outbox changes so list
/// controllers can overlay still-pending writes onto their fetched state.
final pendingWritesProvider = StreamProvider<List<OutboxEntry>>((ref) async* {
  final outbox = ref.watch(outboxProvider);
  yield outbox.all();
  await for (final _ in outbox.watch()) {
    yield outbox.all();
  }
});
