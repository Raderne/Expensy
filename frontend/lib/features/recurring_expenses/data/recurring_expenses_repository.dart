import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../shared/domain/recurring_share_draft.dart';
import '../domain/recurring_expense.dart';
import '../domain/upcoming_bill.dart';

class RecurringExpensesRepository {
  final Dio _dio;
  const RecurringExpensesRepository(this._dio);

  Future<List<RecurringExpense>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/expenses/recurring');
    _ensureOk(res);
    final list = res.data!['recurring'] as List<dynamic>;
    return list
        .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringExpense> create({
    required String label,
    required double amount,
    String? categoryId,
    required RecurrenceFrequency frequency,
    int? intervalDays,
    required DateTime anchorDate,
    List<RecurringShareDraft> shares = const [],
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'label': label,
      'amount': amount,
      'frequency': frequency.wireValue,
      'anchorDate': _isoDate(anchorDate),
    };
    if (categoryId != null) body['categoryId'] = categoryId;
    if (frequency == RecurrenceFrequency.custom) {
      body['intervalDays'] = intervalDays;
    }
    if (shares.isNotEmpty) {
      body['shares'] = shares.map((s) => s.toJson()).toList();
    }

    final res = await _dio.post<Map<String, dynamic>>(
      '/me/expenses/recurring',
      data: body,
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    _ensureOk(res);
    return RecurringExpense.fromJson(
      res.data!['recurring'] as Map<String, dynamic>,
    );
  }

  Future<RecurringExpense> update({
    required String id,
    String? label,
    double? amount,
    String? categoryId,
    RecurrenceFrequency? frequency,
    int? intervalDays,
    bool clearIntervalDays = false,
    DateTime? anchorDate,
    bool? isActive,
    List<RecurringShareDraft>? shares,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (amount != null) body['amount'] = amount;
    if (categoryId != null) body['categoryId'] = categoryId;
    if (frequency != null) body['frequency'] = frequency.wireValue;
    if (clearIntervalDays) {
      body['intervalDays'] = null;
    } else if (intervalDays != null) {
      body['intervalDays'] = intervalDays;
    }
    if (anchorDate != null) body['anchorDate'] = _isoDate(anchorDate);
    if (isActive != null) body['isActive'] = isActive;
    // Non-null replaces the whole template ([] clears it).
    if (shares != null) {
      body['shares'] = shares.map((s) => s.toJson()).toList();
    }

    final res = await _dio.put<Map<String, dynamic>>(
      '/me/expenses/recurring/$id',
      data: body,
    );
    _ensureOk(res);
    return RecurringExpense.fromJson(
      res.data!['recurring'] as Map<String, dynamic>,
    );
  }

  Future<void> remove(String id) async {
    final res = await _dio.delete('/me/expenses/recurring/$id');
    _ensureOk(res);
  }

  Future<List<UpcomingBill>> upcoming({int limit = 3}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/me/expenses/upcoming',
      queryParameters: {'limit': limit},
    );
    _ensureOk(res);
    final list = res.data!['upcoming'] as List<dynamic>;
    return list
        .map((e) => UpcomingBill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _isoDate(DateTime d) {
    final iso = DateTime(d.year, d.month, d.day).toIso8601String();
    return iso; // backend normalizes to start-of-day
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw RecurringExpensesApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

class RecurringExpensesApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const RecurringExpensesApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() =>
      'RecurringExpensesApiException($status, $code): $message';
}

final recurringExpensesRepositoryProvider =
    Provider<RecurringExpensesRepository>(
      (ref) => RecurringExpensesRepository(ref.watch(dioProvider)),
    );
