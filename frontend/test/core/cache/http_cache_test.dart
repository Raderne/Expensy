import 'package:expensy/core/cache/http_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cacheKeyFor', () {
    test('returns path-only key when no query is given', () {
      expect(cacheKeyFor('/me/summary'), 'GET /me/summary');
    });

    test('encodes a single query param', () {
      expect(
        cacheKeyFor('/me/summary', {'month': '2026-05'}),
        'GET /me/summary?month=2026-05',
      );
    });

    test('sorts query params so order does not affect the key', () {
      final a = cacheKeyFor('/x', {'b': '2', 'a': '1'});
      final b = cacheKeyFor('/x', {'a': '1', 'b': '2'});
      expect(a, b);
      expect(a, 'GET /x?a=1&b=2');
    });

    test('drops null-valued params', () {
      expect(
        cacheKeyFor('/transactions', {'month': '2026-05', 'cursor': null}),
        'GET /transactions?month=2026-05',
      );
    });
  });

  group('InMemoryHttpCache', () {
    late InMemoryHttpCache cache;

    setUp(() => cache = InMemoryHttpCache());

    test('returns null on miss', () async {
      expect(await cache.read('nope'), isNull);
    });

    test('round-trips a stored map', () async {
      await cache.write('k', {'a': 1, 'b': 'two'});
      final got = await cache.read('k');
      expect(got, {'a': 1, 'b': 'two'});
    });

    test('clear empties the cache', () async {
      await cache.write('k', {'a': 1});
      await cache.clear();
      expect(await cache.read('k'), isNull);
    });
  });
}
