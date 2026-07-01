import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/budget_rollover.dart';
import 'goals_repository.dart' show GoalsApiException;

/// Reads and allocates leftover budget from closed months (see backend
/// `/me/budget/rollovers`). Allocation moves a leftover into a savings goal.
class RolloversRepository {
  final Dio _dio;
  const RolloversRepository(this._dio);

  Future<List<BudgetRollover>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/budget/rollovers');
    _ensureOk(res);
    final list = res.data!['rollovers'] as List<dynamic>;
    return list
        .map((e) => BudgetRollover.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<BudgetRollover> allocate({
    required String month,
    required String goalId,
    required double amount,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/budget/rollovers/$month/allocate',
      data: {'goalId': goalId, 'amount': amount},
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    _ensureOk(res);
    return BudgetRollover.fromJson(res.data!['rollover'] as Map<String, dynamic>);
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw GoalsApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

final rolloversRepositoryProvider = Provider<RolloversRepository>(
  (ref) => RolloversRepository(ref.watch(dioProvider)),
);
