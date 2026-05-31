import 'package:dio/dio.dart';

import '../data/auth_repository.dart';

/// User-facing copy for failed login/signup actions.
String authErrorMessage(Object error) {
  if (error is AuthApiException) {
    return switch (error.code) {
      'INVALID_CREDENTIALS' => 'Wrong email or password.',
      'EMAIL_TAKEN' => 'That email is already registered.',
      'RATE_LIMITED' => 'Too many attempts. Try again in a few minutes.',
      'VALIDATION_ERROR' => 'Check the fields and try again.',
      _ => error.message,
    };
  }

  if (error is DioException) {
    final base = error.requestOptions.baseUrl;
    final usedLocalhost = base.contains('localhost') || base.contains('127.0.0.1');
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      if (usedLocalhost) {
        return 'Cannot reach the API. On a physical device, use your computer\'s '
            'LAN IP (e.g. http://192.168.1.10:3000), not localhost.';
      }
      return 'Cannot reach the server. Check your connection and try again.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Check your network and try again.';
    }
  }

  return 'Something went wrong. Try again.';
}
