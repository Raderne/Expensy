import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/analytics_breakdown.dart';

class AnalyticsRepository {
  final Dio _dio;
  const AnalyticsRepository(this._dio);

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
    return AnalyticsBreakdown.fromJson(res.data!);
  }
}

class AnalyticsApiException implements Exception {
  final int status;
  final String message;
  const AnalyticsApiException({required this.status, required this.message});

  @override
  String toString() => 'AnalyticsApiException($status): $message';
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.watch(dioProvider)),
);
