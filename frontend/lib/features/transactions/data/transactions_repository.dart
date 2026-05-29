import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/transaction.dart';

class TransactionsPage {
  final List<Transaction> transactions;
  final String? nextCursor;

  const TransactionsPage({required this.transactions, required this.nextCursor});

  bool get hasMore => nextCursor != null;
}

class TransactionsRepository {
  final Dio _dio;
  const TransactionsRepository(this._dio);

  Future<TransactionsPage> list({
    String? month,
    String? categoryId,
    String? type,
    String? cursor,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/transactions',
      queryParameters: {
        'month': ?month,
        'categoryId': ?categoryId,
        'type': ?type,
        'cursor': ?cursor,
      },
    );
    _ensureOk(res);
    final data = res.data!;
    final list = (data['transactions'] as List<dynamic>)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return TransactionsPage(
      transactions: list,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<List<String>> listMonths() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/transaction-months');
    _ensureOk(res);
    return (res.data!['months'] as List<dynamic>).cast<String>();
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    throw TransactionsApiException(
      status: status,
      code: data is Map ? data['code']?.toString() : null,
      message: (data is Map ? data['title']?.toString() : null) ?? 'Request failed',
    );
  }
}

class TransactionsApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const TransactionsApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'TransactionsApiException($status, $code): $message';
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.watch(dioProvider)),
);
