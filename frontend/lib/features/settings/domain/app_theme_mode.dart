import 'package:flutter/material.dart';

/// The user-selectable app theme. [system] follows the phone; [dark] is the
/// charcoal theme; [amoled] is true black for OLED screens.
enum AppThemeMode {
  system,
  light,
  dark,
  amoled;

  /// Stable key persisted to storage. Never reorder — these are written values.
  String get key => switch (this) {
    AppThemeMode.system => 'system',
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.amoled => 'amoled',
  };

  static AppThemeMode fromKey(String? key) => switch (key) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    'amoled' => AppThemeMode.amoled,
    _ => AppThemeMode.system,
  };

  String get label => switch (this) {
    AppThemeMode.system => 'System',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
    AppThemeMode.amoled => 'AMOLED Black',
  };

  String get description => switch (this) {
    AppThemeMode.system => 'Match your phone',
    AppThemeMode.light => 'Always light',
    AppThemeMode.dark => 'Soft charcoal',
    AppThemeMode.amoled => 'True black for OLED',
  };

  IconData get icon => switch (this) {
    AppThemeMode.system => Icons.brightness_auto_rounded,
    AppThemeMode.light => Icons.light_mode_rounded,
    AppThemeMode.dark => Icons.dark_mode_rounded,
    AppThemeMode.amoled => Icons.contrast_rounded,
  };
}
