import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../domain/app_theme_mode.dart';

/// Holds the selected [AppThemeMode], seeded synchronously from persisted
/// storage and written back on every change.
final themeModeProvider = NotifierProvider<ThemeModeController, AppThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    final store = ref.watch(settingsStoreProvider);
    return AppThemeMode.fromKey(store.getString(_key));
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(settingsStoreProvider).setString(_key, mode.key);
  }
}
