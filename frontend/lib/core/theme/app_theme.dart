import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_palette.dart';

/// Builds the project [ThemeData] from design tokens.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData amoled() => _build(Brightness.dark, AppPalette.amoled);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final colorScheme =
        (brightness == Brightness.dark
                ? const ColorScheme.dark()
                : const ColorScheme.light())
            .copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              secondary: AppColors.accent,
              onSecondary: Colors.white,
              surface: palette.surface,
              onSurface: palette.ink,
              error: AppColors.danger,
              onError: Colors.white,
            );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: GoogleFonts.dmSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: palette.ink, displayColor: palette.ink),
      dividerColor: palette.border,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
    );
  }
}
