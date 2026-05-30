import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/http_cache.dart';
import '../../../core/network/dio_client.dart';
import '../domain/dashboard_summary.dart';
import '../domain/recent_transaction.dart';

class DashboardRepository {
  final Dio _dio;
  final HttpCache _cache;
  const DashboardRepository(this._dio, this._cache);

  Future<DashboardSummary> getSummary({required String month}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/me/summary',
      queryParameters: {'month': month},
    );
    _ensureOk(res);
    await _cache.write(_summaryKey(month), res.data!);
    return DashboardSummary.fromJson(res.data!);
  }

  /// Cached read for the SWR pipeline. Returns null on miss / decode failure
  /// so callers can simply fall through to the network fetch.
  Future<DashboardSummary?> readCachedSummary({required String month}) =>
      _readCached(_summaryKey(month), DashboardSummary.fromJson);

  Future<List<RecentTransaction>> getRecentTransactions({int limit = 4}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/transactions/recent',
      queryParameters: {'limit': limit},
    );
    _ensureOk(res);
    await _cache.write(_recentKey(limit), res.data!);
    return _decodeRecent(res.data!);
  }

  Future<List<RecentTransaction>?> readCachedRecentTransactions({int limit = 4}) =>
      _readCached(_recentKey(limit), _decodeRecent);

  static List<RecentTransaction> _decodeRecent(Map<String, dynamic> data) {
    final list = data['transactions'] as List<dynamic>;
    return list
        .map((e) => RecentTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _summaryKey(String month) =>
      cacheKeyFor('/me/summary', {'month': month});
  String _recentKey(int limit) =>
      cacheKeyFor('/transactions/recent', {'limit': limit});

  Future<T?> _readCached<T>(
    String key,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final raw = await _cache.read(key);
    if (raw == null) return null;
    try {
      return decode(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('Cache decode failed for $key: $e');
      return null;
    }
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw DashboardApiException(
        status: status, code: code, message: title ?? 'Request failed');
  }
}

class DashboardApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const DashboardApiException(
      {required this.status, required this.message, this.code});

  @override
  String toString() => 'DashboardApiException($status, $code): $message';
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    ref.watch(dioProvider),
    ref.watch(httpCacheProvider),
  ),
);
