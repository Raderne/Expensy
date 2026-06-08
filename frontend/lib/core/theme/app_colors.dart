import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Design tokens. Brand colors are compile-time `const`; theme-variant tokens
/// (surfaces, text, tints, effects) resolve against the globally-active
/// [AppPalette], which `ExpensyApp` keeps in sync with the resolved brightness
/// (Light / Dark / AMOLED). Never hard-code hex in widgets.
@immutable
class AppColors {
  const AppColors._();

  /// The palette backing the theme-variant getters below. Swapped by
  /// `ExpensyApp.build` before descendants render, so every `AppColors.x`
  /// access reflects the current theme without threading [BuildContext].
  static AppPalette active = AppPalette.light;

  // ── Brand (theme-invariant) ────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B45D0);
  static const Color primaryDark = Color(0xFF0C228E);
  static const Color accent = Color(0xFFF56B1E);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);

  // ── Theme-variant (resolve against [active]) ───────────────────────────────
  static Color get background => active.background;
  static Color get surface => active.surface;
  static Color get surfaceAlt => active.surfaceAlt;
  static Color get border => active.border;
  static Color get ink => active.ink;
  static Color get inkMid => active.inkMid;
  static Color get inkLight => active.inkLight;
  static Color get inkFaint => active.inkFaint;
  static Color get primaryLight => active.primaryLight;
  static Color get accentLight => active.accentLight;
  static Color get successLight => active.successLight;
  static Color get dangerLight => active.dangerLight;
  static Color get primaryInk => active.primaryInk;
  static Color get accentInk => active.accentInk;
  static Color get successInk => active.successInk;
  static Color get dangerInk => active.dangerInk;
  static Color get shadow => active.shadow;
  static Color get scrim => active.scrim;
  static Color get shimmerBase => active.shimmerBase;
  static Color get shimmerHighlight => active.shimmerHighlight;

  // Curated picker palette — must match CATEGORY_PALETTE in backend/src/schemas/categories.ts
  static const List<Color> categoryPalette = [
    Color(0xFFF56B1E),
    Color(0xFFFBBF24),
    Color(0xFF16A34A),
    Color(0xFF0891B2),
    Color(0xFF1B45D0),
    Color(0xFF6366F1),
    Color(0xFF7C3AED),
    Color(0xFF8B5CF6),
    Color(0xFFDB2777),
    Color(0xFFE11D48),
    Color(0xFFDC2626),
    Color(0xFF64748B),
    Color(0xFF0F766E),
    Color(0xFFB45309),
  ];

  static const List<String> categoryPaletteHex = [
    '#F56B1E',
    '#FBBF24',
    '#16A34A',
    '#0891B2',
    '#1B45D0',
    '#6366F1',
    '#7C3AED',
    '#8B5CF6',
    '#DB2777',
    '#E11D48',
    '#DC2626',
    '#64748B',
    '#0F766E',
    '#B45309',
  ];

  // Category palette (key, color, bgTint). bgTint is a light wash used behind
  // category glyphs; kept fixed for brand recognition across themes.
  static const Map<String, CategoryColor> categories = {
    'food': CategoryColor(Color(0xFFF56B1E), Color(0xFFFEF0E8)),
    'travel': CategoryColor(Color(0xFF1B45D0), Color(0xFFE8EFFE)),
    'shop': CategoryColor(Color(0xFF7C3AED), Color(0xFFEDE9FE)),
    'health': CategoryColor(Color(0xFF16A34A), Color(0xFFDCFCE7)),
    'fun': CategoryColor(Color(0xFFDB2777), Color(0xFFFCE7F3)),
    'home': CategoryColor(Color(0xFF0891B2), Color(0xFFCFFAFE)),
    'subscriptions': CategoryColor(Color(0xFF8B5CF6), Color(0xFFEDE9FE)),
  };
}

@immutable
class CategoryColor {
  final Color color;
  final Color bgTint;
  const CategoryColor(this.color, this.bgTint);
}
