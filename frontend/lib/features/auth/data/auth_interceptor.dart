import 'dart:async';

import 'package:dio/dio.dart';

import 'auth_storage.dart';

/// Attaches the access token to every request and transparently refreshes it
/// once on a 401 response. On refresh failure, [onAuthFailure] is invoked so
/// the app can clear state and route to /login.
///
/// The refresh call itself uses [refreshDio] — a bare Dio with no interceptor —
/// to avoid recursive interception.
class AuthInterceptor extends Interceptor {
  final AuthStorage storage;
  final Dio refreshDio;
  final Future<void> Function() onAuthFailure;

  Future<bool>? _inFlightRefresh;

  AuthInterceptor({
    required this.storage,
    required this.refreshDio,
    required this.onAuthFailure,
  });

  static const _retryFlag = 'auth.retried';
  static const _skipAuthFlag = 'auth.skip';

  bool _isAuthEndpoint(String path) =>
      path.contains('/auth/signup') ||
      path.contains('/auth/login') ||
      path.contains('/auth/refresh');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuthFlag] == true || _isAuthEndpoint(options.path)) {
      return handler.next(options);
    }
    final token = await storage.readAccess();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode != 401 ||
        response.requestOptions.extra[_retryFlag] == true ||
        _isAuthEndpoint(response.requestOptions.path)) {
      return handler.next(response);
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      await storage.clear();
      await onAuthFailure();
      return handler.next(response);
    }

    final req = response.requestOptions;
    req.extra[_retryFlag] = true;
    final newAccess = await storage.readAccess();
    if (newAccess != null) {
      req.headers['Authorization'] = 'Bearer $newAccess';
    }
    try {
      final retried = await refreshDio.fetch<dynamic>(req);
      handler.resolve(retried);
    } catch (_) {
      handler.next(response);
    }
  }

  Future<bool> _refreshOnce() {
    return _inFlightRefresh ??= _doRefresh().whenComplete(
      () => _inFlightRefresh = null,
    );
  }

  Future<bool> _doRefresh() async {
    final refresh = await storage.readRefresh();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null) return false;
      final access = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (access == null || newRefresh == null) return false;
      await storage.writeTokens(accessToken: access, refreshToken: newRefresh);
      return true;
    } on DioException {
      return false;
    }
  }
}
