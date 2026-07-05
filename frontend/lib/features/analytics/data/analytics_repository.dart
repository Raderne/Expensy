import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/http_cache.dart';
import '../../../core/network/dio_client.dart';
import '../domain/analytics_breakdown.dart';
import '../domain/spending_insights.dart';

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

  /// Fetches the AI spending insights for [month]. The backend serves a cached
  /// read-out within its TTL; pass [refresh] to force a recompute. Surfaces
  /// `INSUFFICIENT_DATA` / `AI_UNAVAILABLE` as [AnalyticsApiException] so the UI
  /// can branch on `code`.
  Future<SpendingInsights> getInsights({
    required String month,
    bool refresh = false,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/analytics/insights',
        queryParameters: {'month': month, if (refresh) 'refresh': 'true'},
      );
      _ensureOk(res);
      return SpendingInsights.fromJson(
        res.data!['insights'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // 5xx (e.g. 503 AI_UNAVAILABLE) throws before _ensureOk; map it here so
      // the code from the JSON body still reaches the UI.
      throw _fromDioError(e);
    }
  }

  String _key(String month) => cacheKeyFor('/analytics', {'month': month});

  // Non-2xx responses that Dio does not throw on (status < 500, e.g. 422).
  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw AnalyticsApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }

  AnalyticsApiException _fromDioError(DioException e) {
    final data = e.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    return AnalyticsApiException(
      status: e.response?.statusCode ?? 0,
      code: code,
      message: title ?? e.message ?? 'Request failed',
    );
  }
}

class AnalyticsApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const AnalyticsApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AnalyticsApiException($status, $code): $message';
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) =>
      AnalyticsRepository(ref.watch(dioProvider), ref.watch(httpCacheProvider)),
);
