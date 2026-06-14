import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../cache/http_cache.dart';
import '../models/category.dart';
import '../network/dio_client.dart';
import '../sync/outbox.dart';
import '../sync/outbox_writer.dart';

class CategoriesApiException implements Exception {
  final int status;
  final String code;
  final String message;
  const CategoriesApiException({
    required this.status,
    required this.code,
    required this.message,
  });
}

class CategoriesRepository {
  final Dio _dio;
  final OutboxWriter _outbox;
  final HttpCache _cache;
  const CategoriesRepository(this._dio, this._outbox, this._cache);

  static const _cacheKey = 'GET /categories';

  /// Fetches categories, caching the result. Falls back to the last cached copy
  /// when the network/server is unavailable so pickers keep working offline.
  Future<List<Category>> fetch() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/categories');
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('GET /categories failed with $status');
      }
      await _cache.write(_cacheKey, res.data!);
      return _parse(res.data!);
    } catch (_) {
      final cached = await _cache.read(_cacheKey);
      if (cached != null) return _parse(cached);
      rethrow;
    }
  }

  List<Category> _parse(Map<String, dynamic> data) =>
      (data['categories'] as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Queues a category create and returns the optimistic row. The temp id is
  /// reconciled to the server id (and rewritten into any dependent queued write,
  /// e.g. an expense created in this category offline) by the SyncEngine.
  Future<Category> create({
    required String label,
    required String abbr,
    required String colorHex,
  }) async {
    final tempId = _outbox.newTempId();
    await _outbox.enqueue(
      kind: 'categoryCreate',
      method: 'POST',
      path: '/categories',
      tempId: tempId,
      body: {'label': label, 'abbr': abbr, 'color': colorHex},
    );
    return Category(
      id: tempId,
      key: tempId, // not a system key → colorValue falls back to the hex below
      label: label,
      abbr: abbr,
      color: colorHex,
      bgTint: colorHex,
      isSystem: false,
      pending: true,
    );
  }

  Future<void> update({
    required String id,
    String? label,
    String? abbr,
    String? colorHex,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (abbr != null) body['abbr'] = abbr;
    if (colorHex != null) body['color'] = colorHex;
    await _outbox.enqueue(
      kind: 'categoryUpdate',
      method: 'PATCH',
      path: '/categories/$id',
      body: body,
    );
  }

  Future<void> delete(String id) async {
    await _outbox.enqueue(
      kind: 'categoryDelete',
      method: 'DELETE',
      path: '/categories/$id',
    );
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(
    ref.watch(dioProvider),
    ref.watch(outboxWriterProvider),
    ref.watch(httpCacheProvider),
  ),
);

/// Cached for the session — categories rarely change and every feature that
/// needs the picker (add expense, transactions filter) consumes this provider.
/// Gates on auth so we don't fire a request before the user is logged in.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.hasValue || auth.value is! AuthAuthenticated) return const [];
  return ref.watch(categoriesRepositoryProvider).fetch();
});

/// Server categories overlaid with still-pending outbox writes: optimistic
/// creates are appended, queued deletes are hidden. Pickers and management
/// screens watch this so an offline category is usable immediately and vanishes
/// once a delete is queued — both reconcile to canonical data after sync.
/// Stays an [AsyncValue] so widgets keep their loading/error handling.
final categoriesViewProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final base = ref.watch(categoriesProvider);
  final pending = ref.watch(pendingWritesProvider).value ?? const [];
  return base.whenData((cats) => overlayCategories(cats, pending));
});

/// Pure overlay used by [categoriesViewProvider] (and unit tests).
List<Category> overlayCategories(
  List<Category> base,
  List<OutboxEntry> pending,
) {
  if (pending.isEmpty) return base;
  final deleted = <String>{};
  final creates = <Category>[];
  for (final e in pending) {
    switch (e.kind) {
      case 'categoryDelete':
        deleted.add(e.path.split('/').last);
      case 'categoryCreate':
        final b = e.body ?? const {};
        creates.add(
          Category(
            id: e.tempId ?? e.id,
            key: e.tempId ?? e.id,
            label: (b['label'] as String?) ?? '',
            abbr: (b['abbr'] as String?) ?? '',
            color: (b['color'] as String?) ?? '#888888',
            bgTint: (b['color'] as String?) ?? '#888888',
            isSystem: false,
            pending: true,
          ),
        );
    }
  }
  return [...base.where((c) => !deleted.contains(c.id)), ...creates];
}
