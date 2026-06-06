import 'package:flutter/services.dart';

/// Wraps a pull-to-refresh callback with a light haptic on completion. The
/// haptic fires whether the refresh succeeds or fails — the user pulled,
/// the refresh resolved, they should feel the spinner settle.
///
/// The error is rethrown so RefreshIndicator can keep its existing failure
/// semantics (it pulls the spinner up either way; we just add the haptic).
Future<void> Function() withRefreshHaptic(Future<void> Function() refresh) {
  return () async {
    try {
      await refresh();
    } finally {
      await HapticFeedback.lightImpact();
    }
  };
}
