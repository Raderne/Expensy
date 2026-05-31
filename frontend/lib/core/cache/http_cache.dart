import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight, lazy SWR cache for read-only API responses.
///
/// The contract is intentionally minimal: every entry stores a JSON object
/// plus the wall-clock time it was written. The controller layer owns
/// decoding — that keeps Hive away from feature-specific types so the cache
/// can serve any read endpoint without code-gen.
///
/// Entries silently expire after [_maxAge]. We don't bubble that up to the
/// caller — a stale entry is treated the same as a miss, so the controller
/// just falls back to a network fetch. The cap exists to keep truly ancient
/// data (months-old responses, e.g. after a long offline stretch) from being
/// rendered as if it were live.
abstract class HttpCache {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> clear();
}

class HiveHttpCache implements HttpCache {
  HiveHttpCache(this._box);

  static const _boxName = 'http_cache_v1';
  static const _maxAge = Duration(days: 7);

  final Box<String> _box;

  /// Opens the underlying Hive box. Safe to call repeatedly; subsequent calls
  /// short-circuit. Throws if Hive can't initialize (e.g. permission denied) —
  /// callers should fall back to an in-memory cache in that case.
  static Future<HiveHttpCache> open() async {
    if (!_hiveInitialized) {
      // Hive needs an app-private directory; path_provider gives us one that
      // works on every platform Flutter supports (mobile, desktop, web).
      final dir = await getApplicationSupportDirectory();
      Hive.init(dir.path);
      _hiveInitialized = true;
    }
    final box = await Hive.openBox<String>(_boxName);
    return HiveHttpCache(box);
  }

  static bool _hiveInitialized = false;

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _box.delete(key);
        return null;
      }
      final writtenAt = decoded['_writtenAt'];
      if (writtenAt is int) {
        final age = DateTime.now().millisecondsSinceEpoch - writtenAt;
        if (age > _maxAge.inMilliseconds) {
          await _box.delete(key);
          return null;
        }
      }
      final body = decoded['body'];
      return body is Map<String, dynamic> ? body : null;
    } catch (e) {
      // Corrupt entry — discard and treat as a miss.
      if (kDebugMode) debugPrint('HttpCache: dropping corrupt entry $key: $e');
      await _box.delete(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    final envelope = {
      '_writtenAt': DateTime.now().millisecondsSinceEpoch,
      'body': value,
    };
    await _box.put(key, jsonEncode(envelope));
  }

  @override
  Future<void> clear() => _box.clear();
}

/// Fallback used when Hive can't initialize (rare — sandboxed environments,
/// tests). Keeps the SWR pipeline working without offline persistence.
class InMemoryHttpCache implements HttpCache {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    _store[key] = value;
  }

  @override
  Future<void> clear() async => _store.clear();
}

/// Provider for the singleton cache. Set in [main] before `runApp` via
/// `overrideWithValue`, so feature controllers can read it synchronously.
final httpCacheProvider = Provider<HttpCache>((ref) {
  throw StateError(
    'httpCacheProvider was not initialized. '
    'Override it in main() with the result of HiveHttpCache.open().',
  );
});

/// Composes a cache key from path + sorted query parameters so the same
/// logical request maps to the same key regardless of query ordering.
String cacheKeyFor(String path, [Map<String, dynamic>? query]) {
  if (query == null || query.isEmpty) return 'GET $path';
  final entries = query.entries.where((e) => e.value != null).toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final qs = entries.map((e) => '${e.key}=${e.value}').join('&');
  return 'GET $path?$qs';
}
