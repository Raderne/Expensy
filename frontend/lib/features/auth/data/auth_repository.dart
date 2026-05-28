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

  Future<AuthSession> login({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    _ensureOk(res);
    return AuthSession.fromJson(res.data!);
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
    throw AuthApiException(status: status, code: code, message: title ?? 'Request failed');
  }
}

class AuthApiException implements Exception {
  final int status;
  final String? code;
  final String message;
  const AuthApiException({required this.status, required this.message, this.code});

  @override
  String toString() => 'AuthApiException($status, $code): $message';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
