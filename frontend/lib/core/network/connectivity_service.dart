import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper over `connectivity_plus`. It answers one question — does the
/// device have *any* network interface up (wifi/cellular/ethernet)? — not
/// whether the server is actually reachable. Reachability is decided by the
/// wake/health layer ([serverWakerProvider]); a suspended backend looks
/// "online" here right up until a request times out.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// Emits `true`/`false` as the device gains/loses connectivity.
  Stream<bool> get onChanged =>
      _connectivity.onConnectivityChanged.map(_hasNetwork);

  /// One-shot snapshot of the current state.
  Future<bool> check() async =>
      _hasNetwork(await _connectivity.checkConnectivity());
}

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Reactive network-presence flag. Seeds with a one-shot check, then tracks the
/// connectivity stream. `true` until proven otherwise so the first frame doesn't
/// flash an offline banner before the initial check resolves.
final hasNetworkProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.check();
  yield* service.onChanged;
});
