import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/dio_client.dart';
import '../domain/goal.dart';

class GoalsRepository {
  final Dio _dio;
  const GoalsRepository(this._dio);

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<List<Goal>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/goals');
    _ensureOk(res);
    final list = res.data!['goals'] as List<dynamic>;
    return list
        .map((e) => Goal.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Goal> create({
    required String name,
    required String icon,
    required String color,
    required double targetAmount,
    double savedAmount = 0,
    DateTime? targetDate,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/goals',
      data: {
        'name': name,
        'icon': icon,
        'color': color,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        if (targetDate != null) 'targetDate': _dateFmt.format(targetDate),
      },
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
    return Goal.fromJson(res.data!['goal'] as Map<String, dynamic>);
  }

  /// Full update — sends every field so the edit sheet can also clear the
  /// target date (a null `targetDate` clears it server-side).
  Future<Goal> update({
    required String id,
    required String name,
    required String icon,
    required String color,
    required double targetAmount,
    required double savedAmount,
    required DateTime? targetDate,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/me/goals/$id',
      data: {
        'name': name,
        'icon': icon,
        'color': color,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'targetDate': targetDate == null ? null : _dateFmt.format(targetDate),
      },
    );
    _ensureOk(res);
    return Goal.fromJson(res.data!['goal'] as Map<String, dynamic>);
  }

  Future<Goal> addFunds({
    required String id,
    required double amount,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/goals/$id/add-funds',
      data: {'amount': amount},
      options: _idempotent(idempotencyKey),
    );
    _ensureOk(res);
    return Goal.fromJson(res.data!['goal'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final res = await _dio.delete('/me/goals/$id');
    _ensureOk(res);
  }

  /// Builds request options carrying an explicit `Idempotency-Key` so the
  /// backend dedupes a re-submitted write. Null → let the Dio interceptor
  /// attach a per-request key instead.
  Options? _idempotent(String? key) =>
      key == null ? null : Options(headers: {'Idempotency-Key': key});

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw GoalsApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

class GoalsApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const GoalsApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'GoalsApiException($status, $code): $message';
}

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(ref.watch(dioProvider)),
);
