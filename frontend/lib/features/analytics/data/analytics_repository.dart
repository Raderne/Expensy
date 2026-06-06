import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/http_cache.dart';
import '../../../core/network/dio_client.dart';
import '../domain/analytics_breakdown.dart';

class AnalyticsRepository {
  final Dio _dio;
  final HttpCache _cache;
  const AnalyticsRepository(this._dio, this._cache);

  Future<AnalyticsBreakdown> get({required String month}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/analytics',
      queryParameters: {'month': month},
    );
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw AnalyticsApiException(
        status: status,
        message: 'GET /analytics failed',
      );
    }
    await _cache.write(_key(month), res.data!);
    return AnalyticsBreakdown.fromJson(res.data!);
  }

  Future<AnalyticsBreakdown?> readCached({required String month}) async {
    final raw = await _cache.read(_key(month));
    if (raw == null) return null;
    try {
      return AnalyticsBreakdown.fromJson(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics cache decode failed: $e');
      return null;
    }
  }

  String _key(String month) => cacheKeyFor('/analytics', {'month': month});
}

class AnalyticsApiException implements Exception {
  final int status;
  final String message;
  const AnalyticsApiException({required this.status, required this.message});

  @override
  String toString() => 'AnalyticsApiException($status): $message';
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) =>
      AnalyticsRepository(ref.watch(dioProvider), ref.watch(httpCacheProvider)),
);
