import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/pending_occurrence.dart';

class RecurringConfirmationsRepository {
  final Dio _dio;
  const RecurringConfirmationsRepository(this._dio);

  Future<List<PendingOccurrence>> listPending() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/recurring/pending');
    _ensureOk(res);
    final list = res.data!['pending'] as List<dynamic>;
    return list
        .map((e) => PendingOccurrence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Occurrences the user pushed to a later day (awaiting confirm/reschedule).
  Future<List<PendingOccurrence>> listPostponed() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/recurring/postponed');
    _ensureOk(res);
    final list = res.data!['postponed'] as List<dynamic>;
    return list
        .map((e) => PendingOccurrence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Confirm the occurrence — the backend creates the real transaction.
  Future<void> confirm(String id, {String? idempotencyKey}) async {
    final res = await _dio.post(
      '/me/recurring/occurrences/$id/confirm',
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
  }

  /// Re-prompt this occurrence on [date] without touching the recurrence schedule.
  Future<void> postpone(
    String id,
    DateTime date, {
    String? idempotencyKey,
  }) async {
    final res = await _dio.post(
      '/me/recurring/occurrences/$id/postpone',
      data: {
        'postponeTo': DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String(),
      },
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
  }

  /// Undo a postpone — re-prompt on the original scheduled day.
  Future<void> reset(String id, {String? idempotencyKey}) async {
    final res = await _dio.post(
      '/me/recurring/occurrences/$id/reset',
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
  }

  Options? _idempotent(String? key) =>
      key == null ? null : Options(headers: {'Idempotency-Key': key});

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw RecurringConfirmationsApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

class RecurringConfirmationsApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const RecurringConfirmationsApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() =>
      'RecurringConfirmationsApiException($status, $code): $message';
}

final recurringConfirmationsRepositoryProvider =
    Provider<RecurringConfirmationsRepository>(
      (ref) => RecurringConfirmationsRepository(ref.watch(dioProvider)),
    );
