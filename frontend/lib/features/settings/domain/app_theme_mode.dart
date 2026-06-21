import 'package:flutter/material.dart';

/// The user-selectable app theme. [system] follows the phone; [light] is the
/// frosted-glass light theme; [dark] is the glassmorphic charcoal theme.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Stable key persisted to storage. Never reorder — these are written values.
  String get key => switch (this) {
    AppThemeMode.system => 'system',
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
  };

  static AppThemeMode fromKey(String? key) => switch (key) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    // The retired AMOLED theme migrates to the standard dark glass theme.
    'amoled' => AppThemeMode.dark,
    _ => AppThemeMode.system,
  };

  String get label => switch (this) {
    AppThemeMode.system => 'System',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };

  String get description => switch (this) {
    AppThemeMode.system => 'Match your phone',
    AppThemeMode.light => 'Frosted glass, light',
    AppThemeMode.dark => 'Glassmorphic charcoal',
  };

  IconData get icon => switch (this) {
    AppThemeMode.system => Icons.brightness_auto_rounded,
    AppThemeMode.light => Icons.light_mode_rounded,
    AppThemeMode.dark => Icons.dark_mode_rounded,
  };
}
