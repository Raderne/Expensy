import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../models/category.dart';
import '../network/dio_client.dart';

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
  const CategoriesRepository(this._dio);

  Future<List<Category>> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>('/categories');
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('GET /categories failed with $status');
    }
    final list = res.data!['categories'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create({
    required String label,
    required String abbr,
    required String colorHex,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/categories',
        data: {'label': label, 'abbr': abbr, 'color': colorHex},
      );
      return Category.fromJson(res.data!['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApi(e);
    }
  }

  Future<Category> update({
    required String id,
    String? label,
    String? abbr,
    String? colorHex,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (abbr != null) body['abbr'] = abbr;
    if (colorHex != null) body['color'] = colorHex;
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/categories/$id',
        data: body,
      );
      return Category.fromJson(res.data!['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApi(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/categories/$id');
    } on DioException catch (e) {
      _throwApi(e);
    }
  }

  Never _throwApi(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode ?? 0;
    String code = 'UNKNOWN';
    String message = 'Something went wrong';
    if (data is Map<String, dynamic>) {
      code = (data['code'] as String?) ?? code;
      message = (data['message'] as String?) ?? message;
    }
    throw CategoriesApiException(status: status, code: code, message: message);
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(dioProvider)),
);

/// Cached for the session — categories rarely change and every feature that
/// needs the picker (add expense, transactions filter) consumes this provider.
/// Gates on auth so we don't fire a request before the user is logged in.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.hasValue || auth.value is! AuthAuthenticated) return const [];
  return ref.watch(categoriesRepositoryProvider).fetch();
});
