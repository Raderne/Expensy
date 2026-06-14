import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';

enum ServerWakeState {
  /// No wake attempt in flight; reachability unknown or last attempt succeeded.
  idle,

  /// A `/health` probe (with retries) is currently running.
  waking,

  /// The server answered `200` on the last probe.
  awake,

  /// Backoff exhausted without a healthy response.
  unreachable,
}

/// Pings `GET /health` to detect — and transparently wait out — a suspended
/// free-tier backend (Fly.io `suspend` / Render sleep). A cold machine answers
/// within a few seconds once woken, so we retry with exponential backoff rather
/// than failing the user's request outright.
///
/// Uses a *bare* Dio (no auth/idempotency/wake interceptors) so a probe can't
/// recurse back into the wake path or trip a token refresh.
class ServerHealth extends Notifier<ServerWakeState> {
  /// Per-probe timeout. A warm server replies in well under a second; a cold one
  /// needs room to boot, so we keep each attempt generous but bounded.
  static const _probeTimeout = Duration(seconds: 6);

  /// Backoff delays between probes. The number of entries caps total wait time
  /// (~1+2+4+8+8 = 23s of sleeping plus probe time) before we give up.
  static const _backoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 8),
  ];

  Dio? _probeDio;
  Future<bool>? _inFlight;

  @override
  ServerWakeState build() => ServerWakeState.idle;

  Dio get _dio => _probeDio ??= Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: _probeTimeout,
      receiveTimeout: _probeTimeout,
      headers: const {'Accept': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  /// Probes the server, retrying through [_backoff] until it answers `200` or
  /// the schedule is exhausted. Single-flight: concurrent callers share one
  /// run and await the same result. Returns `true` if the server is awake.
  Future<bool> wake() {
    return _inFlight ??= _run()..whenComplete(() => _inFlight = null);
  }

  Future<bool> _run() async {
    state = ServerWakeState.waking;
    // Attempt count is backoff length + 1 (an immediate first try, then a probe
    // after each delay).
    for (var attempt = 0; attempt <= _backoff.length; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_backoff[attempt - 1]);
      if (await _probe()) {
        state = ServerWakeState.awake;
        return true;
      }
    }
    state = ServerWakeState.unreachable;
    return false;
  }

  Future<bool> _probe() async {
    try {
      final res = await _dio.get<dynamic>('/health');
      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('ServerHealth: probe failed: $e');
      return false;
    }
  }
}

final serverWakerProvider = NotifierProvider<ServerHealth, ServerWakeState>(
  ServerHealth.new,
);
