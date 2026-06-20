import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/owed_overview.dart';

/// Reads the "who owes me" overview and records repayments. Repayments post
/// directly (with a button loader) rather than through the outbox, so the user
/// gets immediate success/failure instead of a background "syncing" banner.
class SharedRepository {
  final Dio _dio;
  const SharedRepository(this._dio);

  Future<OwedOverview> owed() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/shared/owed');
    _ensureOk(res);
    return OwedOverview.fromJson(res.data!);
  }

  /// [idempotencyKey] keeps a retried submit from double-recording the same
  /// repayment server-side.
  Future<void> recordReimbursement({
    required String splitId,
    required double amount,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async {
    // Day granularity (matching expenses/income) so repayments order by
    // creation within their day rather than floating to the top on time-of-day.
    final raw = occurredAt ?? DateTime.now();
    final when = DateTime(raw.year, raw.month, raw.day);
    final res = await _dio.post(
      '/me/shared/splits/$splitId/reimbursements',
      data: {'amount': amount, 'occurredAt': when.toUtc().toIso8601String()},
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    _ensureOk(res);
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    throw SharedApiException(
      status: status,
      message: (data is Map ? data['title']?.toString() : null) ?? 'Request failed',
    );
  }
}

class SharedApiException implements Exception {
  final int status;
  final String message;
  const SharedApiException({required this.status, required this.message});

  @override
  String toString() => 'SharedApiException($status): $message';
}

final sharedRepositoryProvider = Provider<SharedRepository>(
  (ref) => SharedRepository(ref.watch(dioProvider)),
);
