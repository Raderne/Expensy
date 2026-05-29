import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_user.dart';

class ProfileRepository {
  final Dio _dio;
  const ProfileRepository(this._dio);

  Future<AuthUser> updateName(String name) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/me',
      data: {'name': name},
    );
    _ensureOk(res);
    return AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _dio.patch(
      '/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    _ensureOk(res);
  }

  Future<double> updateBudget(double amount) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/me/budget',
      data: {'amount': amount},
    );
    _ensureOk(res);
    return (res.data!['budget']['amount'] as num).toDouble();
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw ProfileApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

class ProfileApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const ProfileApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ProfileApiException($status, $code): $message';
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);
