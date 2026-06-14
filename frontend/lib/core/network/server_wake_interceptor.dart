import 'package:dio/dio.dart';

/// Outermost error interceptor: when a request fails because the *server* is
/// unreachable (connection refused / timed out) while the device still has a
/// network, it transparently warms the backend via [wake] and replays the
/// original request once.
///
/// Mirrors the existing 401-refresh-and-retry contract in [AuthInterceptor]:
/// the same [RequestOptions] is re-sent, so the stable `Idempotency-Key` rides
/// along and the replay is a server-side no-op if the first attempt actually
/// landed. A one-shot flag in `options.extra` prevents the replay from looping.
class ServerWakeRetryInterceptor extends Interceptor {
  ServerWakeRetryInterceptor({
    required this.dio,
    required this.wake,
    required this.hasNetwork,
  });

  /// The app Dio, used to replay the request through the full chain.
  final Dio dio;

  /// Warms the server; resolves `true` once it answers `200`.
  final Future<bool> Function() wake;

  /// Whether the device currently has any network interface up.
  final Future<bool> Function() hasNetwork;

  static const _retriedFlag = '__wakeRetried';

  static bool _isConnectionError(DioException err) => switch (err.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retriedFlag] == true;

    if (!_isConnectionError(err) || alreadyRetried || !await hasNetwork()) {
      // Genuinely offline, a non-connection error, or we already gave it a
      // second chance — let the caller fall back to cache/outbox.
      return handler.next(err);
    }

    final awake = await wake();
    if (!awake) return handler.next(err);

    options.extra[_retriedFlag] = true;
    try {
      final res = await dio.fetch<dynamic>(options);
      return handler.resolve(res);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
