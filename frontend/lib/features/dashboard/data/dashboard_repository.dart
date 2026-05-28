import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/dashboard_summary.dart';
import '../domain/recent_transaction.dart';

class DashboardRepository {
  final Dio _dio;
  const DashboardRepository(this._dio);

  Future<DashboardSummary> getSummary({required String month}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/me/summary',
      queryParameters: {'month': month},
    );
    _ensureOk(res);
    return DashboardSummary.fromJson(res.data!);
  }

  Future<List<RecentTransaction>> getRecentTransactions({int limit = 4}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/transactions/recent',
      queryParameters: {'limit': limit},
    );
    _ensureOk(res);
    final list = res.data!['transactions'] as List<dynamic>;
    return list
        .map((e) => RecentTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw DashboardApiException(status: status, code: code, message: title ?? 'Request failed');
  }
}

class DashboardApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const DashboardApiException({required this.status, required this.message, this.code});

  @override
  String toString() => 'DashboardApiException($status, $code): $message';
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);
