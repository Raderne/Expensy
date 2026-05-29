import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../models/category.dart';
import '../network/dio_client.dart';

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
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
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
