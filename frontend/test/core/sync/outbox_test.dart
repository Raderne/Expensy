import 'package:expensy/core/sync/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

OutboxEntry _entry({
  required String id,
  required int createdAt,
  String kind = 'txCreate',
  OutboxStatus status = OutboxStatus.pending,
}) => OutboxEntry(
  id: id,
  createdAt: createdAt,
  kind: kind,
  method: 'POST',
  path: '/transactions',
  idempotencyKey: 'idem-$id',
  body: const {'amount': 12.5, 'categoryId': 'cat1'},
  tempId: 'tmp_$id',
  status: status,
);

void main() {
  group('OutboxEntry', () {
    test('round-trips through JSON', () {
      final e = _entry(
        id: 'a',
        createdAt: 100,
        status: OutboxStatus.failed,
      ).copyWith(retryCount: 2, lastError: 'HTTP 422');
      final back = OutboxEntry.fromJson(e.toJson());

      expect(back.id, 'a');
      expect(back.createdAt, 100);
      expect(back.kind, 'txCreate');
      expect(back.method, 'POST');
      expect(back.path, '/transactions');
      expect(back.idempotencyKey, 'idem-a');
      expect(back.body, {'amount': 12.5, 'categoryId': 'cat1'});
      expect(back.tempId, 'tmp_a');
      expect(back.status, OutboxStatus.failed);
      expect(back.retryCount, 2);
      expect(back.lastError, 'HTTP 422');
    });

    test('defaults missing status to pending', () {
      final json = {
        'id': 'x',
        'createdAt': 1,
        'kind': 'txDelete',
        'method': 'DELETE',
        'path': '/transactions/1',
        'idempotencyKey': 'k',
      };
      expect(OutboxEntry.fromJson(json).status, OutboxStatus.pending);
    });

    test('copyWith clears the error when asked', () {
      final e = _entry(id: 'a', createdAt: 1).copyWith(lastError: 'boom');
      expect(e.copyWith(clearError: true).lastError, isNull);
    });
  });

  group('InMemoryOutbox', () {
    late InMemoryOutbox outbox;
    setUp(() => outbox = InMemoryOutbox());

    test('returns entries oldest-first regardless of insert order', () async {
      await outbox.enqueue(_entry(id: 'c', createdAt: 300));
      await outbox.enqueue(_entry(id: 'a', createdAt: 100));
      await outbox.enqueue(_entry(id: 'b', createdAt: 200));

      expect(outbox.all().map((e) => e.id), ['a', 'b', 'c']);
    });

    test('pending and failed counts reflect entry status', () async {
      await outbox.enqueue(_entry(id: 'a', createdAt: 1));
      await outbox.enqueue(
        _entry(id: 'b', createdAt: 2, status: OutboxStatus.failed),
      );
      expect(outbox.pendingCount, 1);
      expect(outbox.failedCount, 1);
    });

    test('remove and clear mutate the queue', () async {
      await outbox.enqueue(_entry(id: 'a', createdAt: 1));
      await outbox.enqueue(_entry(id: 'b', createdAt: 2));
      await outbox.remove('a');
      expect(outbox.all().map((e) => e.id), ['b']);
      await outbox.clear();
      expect(outbox.all(), isEmpty);
    });

    test('watch fires on mutation', () async {
      final events = <void>[];
      final sub = outbox.watch().listen(events.add);
      await outbox.enqueue(_entry(id: 'a', createdAt: 1));
      await outbox.remove('a');
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 2);
      await sub.cancel();
    });
  });
}
