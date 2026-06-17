import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/http_cache.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/transaction.dart';

class TransactionsPage {
  final List<Transaction> transactions;
  final String? nextCursor;

  const TransactionsPage({
    required this.transactions,
    required this.nextCursor,
  });

  bool get hasMore => nextCursor != null;
}

class TransactionsRepository {
  final Dio _dio;
  final HttpCache _cache;
  final OutboxWriter _outbox;
  const TransactionsRepository(this._dio, this._cache, this._outbox);

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
    final page = _decodePage(data);
    // Only the unfiltered, first-page snapshot of a given month is cached.
    // Filtered / paginated views have low cache hit value and would balloon
    // disk usage if we tried to cache every combination.
    if (cursor == null && categoryId == null && type == null && month != null) {
      await _cache.write(_listKey(month), data);
    }
    return page;
  }

  Future<TransactionsPage?> readCachedFirstPage({required String month}) async {
    final raw = await _cache.read(_listKey(month));
    if (raw == null) return null;
    try {
      return _decodePage(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('Transactions cache decode failed: $e');
      return null;
    }
  }

  Future<List<String>> listMonths() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/transaction-months');
    _ensureOk(res);
    final months = (res.data!['months'] as List<dynamic>).cast<String>();
    await _cache.write(_monthsKey(), res.data!);
    return months;
  }

  Future<List<String>?> readCachedMonths() async {
    final raw = await _cache.read(_monthsKey());
    if (raw == null) return null;
    try {
      return (raw['months'] as List<dynamic>).cast<String>();
    } catch (e) {
      if (kDebugMode) debugPrint('Months cache decode failed: $e');
      return null;
    }
  }

  /// Queues a soft-delete. The row is hidden optimistically (see the
  /// transactions overlay); the actual DELETE replays via the SyncEngine.
  Future<void> delete(String id) async {
    await _outbox.enqueue(
      kind: 'txDelete',
      method: 'DELETE',
      path: '/transactions/$id',
    );
  }

  static TransactionsPage _decodePage(Map<String, dynamic> data) {
    final list = (data['transactions'] as List<dynamic>)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return TransactionsPage(
      transactions: list,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  String _listKey(String month) =>
      cacheKeyFor('/transactions', {'month': month});
  String _monthsKey() => cacheKeyFor('/me/transaction-months');

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    throw TransactionsApiException(
      status: status,
      code: data is Map ? data['code']?.toString() : null,
      message:
          (data is Map ? data['title']?.toString() : null) ?? 'Request failed',
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
  (ref) => TransactionsRepository(
    ref.watch(dioProvider),
    ref.watch(httpCacheProvider),
    ref.watch(outboxWriterProvider),
  ),
);
