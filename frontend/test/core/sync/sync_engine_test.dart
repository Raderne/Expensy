import 'package:dio/dio.dart';
import 'package:expensy/core/network/connectivity_service.dart';
import 'package:expensy/core/network/dio_client.dart';
import 'package:expensy/core/network/server_health.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:expensy/core/sync/sync_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

/// Connectivity that always reports "online" without touching the platform.
class _AlwaysOnline extends ConnectivityService {
  @override
  Future<bool> check() async => true;
}

/// Waker that resolves immediately without a real /health probe.
class _FakeWaker extends ServerHealth {
  @override
  Future<bool> wake() async => true;
}

OutboxEntry _entry({
  required String id,
  required int createdAt,
  required String kind,
  required String method,
  required String path,
  Map<String, dynamic>? body,
  String? tempId,
}) => OutboxEntry(
  id: id,
  createdAt: createdAt,
  kind: kind,
  method: method,
  path: path,
  idempotencyKey: 'idem-$id',
  body: body,
  tempId: tempId,
);

Response<dynamic> _resp(String path, int status, [dynamic data]) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: data,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(RequestOptions(path: '/'));
  });

  late _MockDio dio;
  late InMemoryOutbox outbox;
  late ProviderContainer container;

  ProviderContainer build() => ProviderContainer(
    overrides: [
      outboxProvider.overrideWithValue(outbox),
      dioProvider.overrideWithValue(dio),
      connectivityServiceProvider.overrideWithValue(_AlwaysOnline()),
      serverWakerProvider.overrideWith(_FakeWaker.new),
    ],
  );

  setUp(() {
    dio = _MockDio();
    outbox = InMemoryOutbox();
  });

  tearDown(() => container.dispose());

  test('drains a successful create and removes it from the queue', () async {
    when(
      () => dio.request<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => _resp('/transactions', 201, {
        'transaction': {'id': 'realTx'},
      }),
    );

    await outbox.enqueue(
      _entry(
        id: 'a',
        createdAt: 1,
        kind: 'txCreate',
        method: 'POST',
        path: '/transactions',
        body: {'amount': 10, 'categoryId': 'c1'},
        tempId: 'tmp_a',
      ),
    );

    container = build();
    await container.read(syncEngineProvider.notifier).process();

    expect(outbox.all(), isEmpty);
    expect(container.read(syncEngineProvider).lastSyncedAt, isNotNull);
  });

  test('rewrites a temp category id into a later dependent write', () async {
    final captured = <Map<String, dynamic>?>[];
    when(
      () => dio.request<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((inv) async {
      final path = inv.positionalArguments[0] as String;
      final data = inv.namedArguments[#data] as Map<String, dynamic>?;
      captured.add(data);
      if (path == '/categories') {
        return _resp(path, 201, {
          'category': {'id': 'realCat'},
        });
      }
      return _resp(path, 201, {
        'transaction': {'id': 'realTx'},
      });
    });

    // Create a category offline, then an expense that references its temp id.
    await outbox.enqueue(
      _entry(
        id: 'cat',
        createdAt: 1,
        kind: 'categoryCreate',
        method: 'POST',
        path: '/categories',
        body: {'label': 'Coffee', 'abbr': 'COF', 'color': '#abcdef'},
        tempId: 'tmp_cat',
      ),
    );
    await outbox.enqueue(
      _entry(
        id: 'tx',
        createdAt: 2,
        kind: 'txCreate',
        method: 'POST',
        path: '/transactions',
        body: {'amount': 5, 'categoryId': 'tmp_cat'},
        tempId: 'tmp_tx',
      ),
    );

    container = build();
    await container.read(syncEngineProvider.notifier).process();

    expect(outbox.all(), isEmpty);
    // Second request (the expense) must carry the resolved real category id.
    final expenseBody = captured.last;
    expect(expenseBody?['categoryId'], 'realCat');
  });

  test('treats 404 as already-applied and drops the entry', () async {
    when(
      () => dio.request<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => _resp('/transactions/x', 404));

    await outbox.enqueue(
      _entry(
        id: 'd',
        createdAt: 1,
        kind: 'txDelete',
        method: 'DELETE',
        path: '/transactions/x',
      ),
    );

    container = build();
    await container.read(syncEngineProvider.notifier).process();
    expect(outbox.all(), isEmpty);
  });

  test('dead-letters a validation error but keeps draining', () async {
    when(
      () => dio.request<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((inv) async {
      final path = inv.positionalArguments[0] as String;
      if (path == '/bad') return _resp(path, 422, {'message': 'nope'});
      return _resp(path, 201, {
        'transaction': {'id': 'ok'},
      });
    });

    await outbox.enqueue(
      _entry(
        id: 'bad',
        createdAt: 1,
        kind: 'txCreate',
        method: 'POST',
        path: '/bad',
        body: const {},
      ),
    );
    await outbox.enqueue(
      _entry(
        id: 'good',
        createdAt: 2,
        kind: 'txCreate',
        method: 'POST',
        path: '/transactions',
        body: const {'amount': 1, 'categoryId': 'c1'},
        tempId: 'tmp_good',
      ),
    );

    container = build();
    await container.read(syncEngineProvider.notifier).process();

    final remaining = outbox.all();
    expect(remaining.length, 1);
    expect(remaining.single.id, 'bad');
    expect(remaining.single.status, OutboxStatus.failed);
    expect(outbox.failedCount, 1);
  });

  test('stops the run on a connection error, preserving the queue', () async {
    when(
      () => dio.request<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/transactions'),
        type: DioExceptionType.connectionError,
      ),
    );

    await outbox.enqueue(
      _entry(
        id: 'a',
        createdAt: 1,
        kind: 'txCreate',
        method: 'POST',
        path: '/transactions',
        body: const {'amount': 1, 'categoryId': 'c1'},
        tempId: 'tmp_a',
      ),
    );

    container = build();
    await container.read(syncEngineProvider.notifier).process();

    expect(outbox.all().length, 1);
    expect(outbox.all().single.status, OutboxStatus.pending);
    expect(container.read(syncEngineProvider).lastSyncedAt, isNull);
  });
}
