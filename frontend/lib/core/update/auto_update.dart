import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_store.dart';
import 'update_controller.dart';

const _kIntervalDays = 7;

/// Session guard: prevents repeated dashboard rebuilds from queuing multiple
/// checks within the same app session.
final autoUpdateCheckedProvider =
    NotifierProvider<BoolFlagNotifier, bool>(BoolFlagNotifier.new);

/// Cold-start path: session-gated + 7-day interval-gated.
/// Call once from the dashboard's post-frame callback.
Future<void> maybeAutoCheckOnLaunch(WidgetRef ref) async {
  if (ref.read(autoUpdateCheckedProvider)) return;
  ref.read(autoUpdateCheckedProvider.notifier).set(true);
  await _maybeCheck(ref);
}

/// Resume path: 7-day interval-gated only.
/// Call from didChangeAppLifecycleState → resumed.
Future<void> maybeAutoCheckOnResume(WidgetRef ref) async {
  await _maybeCheck(ref);
}

Future<void> _maybeCheck(WidgetRef ref) async {
  final store = ref.read(settingsStoreProvider);
  final raw = store.getString(lastUpdateCheckKey);
  if (raw != null && raw.isNotEmpty) {
    final last = DateTime.tryParse(raw);
    if (last != null &&
        DateTime.now().difference(last).inDays < _kIntervalDays) {
      return;
    }
  }
  // Write the timestamp before the network call so a concurrent resume event
  // can't trigger a second in-flight check.
  await store.setString(lastUpdateCheckKey, DateTime.now().toIso8601String());
  ref.read(updateControllerProvider.notifier).checkForUpdate();
}
