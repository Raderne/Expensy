import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/owed_overview.dart';

/// Reads the "who owes me" overview and queues repayment writes. Reimbursements
/// go through the outbox so they survive offline; the overview is refetched
/// after a successful sync.
class SharedRepository {
  final Dio _dio;
  final OutboxWriter _outbox;
  const SharedRepository(this._dio, this._outbox);

  Future<OwedOverview> owed() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/shared/owed');
    _ensureOk(res);
    return OwedOverview.fromJson(res.data!);
  }

  Future<void> recordReimbursement({
    required String splitId,
    required double amount,
    DateTime? occurredAt,
  }) async {
    final when = occurredAt ?? DateTime.now();
    await _outbox.enqueue(
      kind: 'reimbursementCreate',
      method: 'POST',
      path: '/me/shared/splits/$splitId/reimbursements',
      body: {'amount': amount, 'occurredAt': when.toUtc().toIso8601String()},
    );
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
  (ref) => SharedRepository(ref.watch(dioProvider), ref.watch(outboxWriterProvider)),
);
