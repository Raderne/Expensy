import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/auth_tokens.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  final Dio _dio;
  const AuthRepository(this._dio);

  Future<AuthSession> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {'email': email, 'password': password, 'name': name},
    );
    _ensureOk(res);
    return AuthSession.fromJson(res.data!);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    _ensureOk(res);
    return AuthSession.fromJson(res.data!);
  }

  /// Requests a password-reset code. The server responds 200 whether or not the
  /// email is registered, so this never reveals account existence.
  Future<void> forgotPassword(String email) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
    );
    _ensureOk(res);
  }

  /// Sets a new password using the emailed 6-digit code.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
    _ensureOk(res);
  }

  Future<AuthUser> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/me');
    _ensureOk(res);
    return AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final code = data is Map ? data['code']?.toString() : null;
    final title = data is Map ? data['title']?.toString() : null;
    throw AuthApiException(
      status: status,
      code: code,
      message: title ?? 'Request failed',
    );
  }
}

class AuthApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const AuthApiException({
    required this.status,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthApiException($status, $code): $message';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
