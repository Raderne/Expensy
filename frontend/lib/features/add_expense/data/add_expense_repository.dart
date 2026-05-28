import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../dashboard/domain/recent_transaction.dart';

class AddExpenseRepository {
  final Dio _dio;
  const AddExpenseRepository(this._dio);

  Future<RecentTransaction> createExpense({
    required String categoryId,
    required double amount,
    String? note,
    DateTime? occurredAt,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: {
        'categoryId': categoryId,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
        if (occurredAt != null) 'occurredAt': occurredAt.toUtc().toIso8601String(),
      },
    );

    final status = res.statusCode ?? 0;
    final data = res.data;
    if (status < 200 || status >= 300 || data == null) {
      throw AddExpenseApiException(
        status: status,
        code: data?['code']?.toString(),
        message: data?['title']?.toString() ?? 'Could not save expense',
      );
    }

    final tx = data['transaction'] as Map<String, dynamic>;
    return RecentTransaction.fromJson(tx);
  }
}

class AddExpenseApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const AddExpenseApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AddExpenseApiException($status, $code): $message';
}

final addExpenseRepositoryProvider = Provider<AddExpenseRepository>(
  (ref) => AddExpenseRepository(ref.watch(dioProvider)),
);
