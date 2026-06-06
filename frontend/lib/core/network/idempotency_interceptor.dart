import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Attaches an `Idempotency-Key` header to every write request so the backend
/// can reject/replay duplicates (a slow request the user re-triggers, or a
/// transparent retry such as the 401-refresh path).
///
/// If a caller already set an `Idempotency-Key` (e.g. a form that reuses one
/// stable key for its whole lifetime to defeat double-taps), that value is left
/// untouched. Otherwise a fresh UUID is generated per request — enough to make
/// transparent retries idempotent, since the 401-refresh retry reuses the same
/// [RequestOptions] (and therefore the same header).
class IdempotencyInterceptor extends Interceptor {
  static const _writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};
  static const _header = 'Idempotency-Key';

  final Uuid _uuid;

  IdempotencyInterceptor({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_writeMethods.contains(options.method.toUpperCase()) &&
        !options.headers.containsKey(_header)) {
      options.headers[_header] = _uuid.v4();
    }
    handler.next(options);
  }
}
