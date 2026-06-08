import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/recurring_income.dart';

class IncomeRepository {
  final Dio _dio;
  const IncomeRepository(this._dio);

  Future<List<RecurringIncome>> listRecurring() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/income/recurring');
    _ensureOk(res);
    final list = res.data!['recurring'] as List<dynamic>;
    return list
        .map((e) => RecurringIncome.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringIncome> createRecurring({
    required String label,
    required double amount,
    required int dayOfMonth,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/income/recurring',
      data: {'label': label, 'amount': amount, 'dayOfMonth': dayOfMonth},
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
    return RecurringIncome.fromJson(
      res.data!['recurring'] as Map<String, dynamic>,
    );
  }

  Future<RecurringIncome> updateRecurring({
    required String id,
    String? label,
    double? amount,
    int? dayOfMonth,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (amount != null) body['amount'] = amount;
    if (dayOfMonth != null) body['dayOfMonth'] = dayOfMonth;
    if (isActive != null) body['isActive'] = isActive;

    final res = await _dio.put<Map<String, dynamic>>(
      '/me/income/recurring/$id',
      data: body,
    );
    _ensureOk(res);
    return RecurringIncome.fromJson(
      res.data!['recurring'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteRecurring(String id) async {
    final res = await _dio.delete('/me/income/recurring/$id');
    _ensureOk(res);
  }

  Future<void> createSideIncome({
    required double amount,
    String? note,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{'amount': amount};
    if (note != null && note.isNotEmpty) body['note'] = note;
    if (occurredAt != null) {
      body['occurredAt'] = occurredAt.toUtc().toIso8601String();
    }

    final res = await _dio.post(
      '/me/income',
      data: body,
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
  }

  /// Builds request options carrying an explicit `Idempotency-Key` so the
  /// backend dedupes a re-submitted create. Null → let the Dio interceptor
  /// attach a per-request key instead.
  Options? _idempotent(String? key) =>
      key == null ? null : Options(headers: {'Idempotency-Key': key});

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw IncomeApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

class IncomeApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const IncomeApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'IncomeApiException($status, $code): $message';
}

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (ref) => IncomeRepository(ref.watch(dioProvider)),
);
