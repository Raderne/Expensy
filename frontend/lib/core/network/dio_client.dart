import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_interceptor.dart';
import '../../features/auth/data/auth_storage.dart';

const _kBaseHeaders = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
};

BaseOptions _defaultOptions() => BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: _kBaseHeaders,
      validateStatus: (status) => status != null && status < 500,
    );

/// Bare Dio used by [AuthInterceptor] to call `/auth/refresh` and retry
/// requests without re-entering the interceptor chain.
final refreshDioProvider = Provider<Dio>((ref) => Dio(_defaultOptions()));

/// App-wide Dio. Carries the auth interceptor; every feature should depend
/// on this provider rather than constructing its own client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_defaultOptions());
  final storage = ref.watch(authStorageProvider);
  final refreshDio = ref.watch(refreshDioProvider);

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      refreshDio: refreshDio,
      onAuthFailure: () async {
        await ref.read(authControllerProvider.notifier).onTokensInvalidated();
      },
    ),
  );
  return dio;
});
