import 'package:flutter/material.dart';

/// Theme-variant design tokens — every color that differs between Light, Dark,
/// and AMOLED lives here and is resolved per [BuildContext] via `context.colors`.
///
/// Brand-invariant colors (primary, accent, success, danger, the category
/// palette) stay as `static const` in [AppColors]. The rule for contributors:
/// brand colors → `AppColors.*`; surfaces / text / tints / shadows →
/// `context.colors.*`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.ink,
    required this.inkMid,
    required this.inkLight,
    required this.inkFaint,
    required this.primaryLight,
    required this.accentLight,
    required this.successLight,
    required this.dangerLight,
    required this.primaryInk,
    required this.accentInk,
    required this.successInk,
    required this.dangerInk,
    required this.shadow,
    required this.scrim,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  // Ink (text)
  final Color ink;
  final Color inkMid;
  final Color inkLight;
  final Color inkFaint;

  // Brand tints (backgrounds for chips/badges)
  final Color primaryLight;
  final Color accentLight;
  final Color successLight;
  final Color dangerLight;

  // Brand ink (legible brand-colored text/icons sitting on the tints above;
  // brightened in dark themes where the saturated brand hues read poorly).
  final Color primaryInk;
  final Color accentInk;
  final Color successInk;
  final Color dangerInk;

  // Effects
  final Color shadow;
  final Color scrim;
  final Color shimmerBase;
  final Color shimmerHighlight;

  /// Light theme — the app's original palette.
  static const light = AppPalette(
    background: Color(0xFFEEF3FF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F8FF),
    border: Color(0xFFDDE6FF),
    ink: Color(0xFF0C1530),
    inkMid: Color(0xFF4A5675),
    inkLight: Color(0xFF7A8AAA),
    inkFaint: Color(0xFFD5DDF0),
    primaryLight: Color(0xFFE8EFFE),
    accentLight: Color(0xFFFEF0E8),
    successLight: Color(0xFFDCFCE7),
    dangerLight: Color(0xFFFEE2E2),
    primaryInk: Color(0xFF1B45D0),
    accentInk: Color(0xFFF56B1E),
    successInk: Color(0xFF16A34A),
    dangerInk: Color(0xFFDC2626),
    shadow: Color(0x10000C22),
    scrim: Color(0x66000C22),
    shimmerBase: Color(0xFFD5DDF0),
    shimmerHighlight: Color(0xFFECF1FA),
  );

  /// Dark theme — soft charcoal, comfortable for low-light without the harsh
  /// contrast of pure black.
  static const dark = AppPalette(
    background: Color(0xFF0E1322),
    surface: Color(0xFF161B2B),
    surfaceAlt: Color(0xFF1E2538),
    border: Color(0xFF283047),
    ink: Color(0xFFF2F5FC),
    inkMid: Color(0xFFB9C2D9),
    inkLight: Color(0xFF8A93AD),
    inkFaint: Color(0xFF39425C),
    primaryLight: Color(0xFF1B2540),
    accentLight: Color(0xFF2E1F14),
    successLight: Color(0xFF13291E),
    dangerLight: Color(0xFF2E1A1C),
    primaryInk: Color(0xFF8AAAFF),
    accentInk: Color(0xFFFB923C),
    successInk: Color(0xFF4ADE80),
    dangerInk: Color(0xFFF87171),
    shadow: Color(0x40000000),
    scrim: Color(0x99000000),
    shimmerBase: Color(0xFF1E2538),
    shimmerHighlight: Color(0xFF283047),
  );

  /// AMOLED theme — pure-black surfaces with hairline borders and a slightly
  /// lifted [surfaceAlt] so cards read as distinct panels without shadows.
  static const amoled = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF0A0D14),
    surfaceAlt: Color(0xFF13161F),
    border: Color(0xFF1C2334),
    ink: Color(0xFFFFFFFF),
    inkMid: Color(0xFFC2CADE),
    inkLight: Color(0xFF8A93AD),
    inkFaint: Color(0xFF2A3144),
    primaryLight: Color(0xFF121A30),
    accentLight: Color(0xFF221710),
    successLight: Color(0xFF0C2016),
    dangerLight: Color(0xFF241315),
    primaryInk: Color(0xFF93B1FF),
    accentInk: Color(0xFFFFA04D),
    successInk: Color(0xFF5CE48E),
    dangerInk: Color(0xFFFF8787),
    shadow: Color(0x66000000),
    scrim: Color(0xB3000000),
    shimmerBase: Color(0xFF13161F),
    shimmerHighlight: Color(0xFF1C2334),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? ink,
    Color? inkMid,
    Color? inkLight,
    Color? inkFaint,
    Color? primaryLight,
    Color? accentLight,
    Color? successLight,
    Color? dangerLight,
    Color? primaryInk,
    Color? accentInk,
    Color? successInk,
    Color? dangerInk,
    Color? shadow,
    Color? scrim,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMid: inkMid ?? this.inkMid,
      inkLight: inkLight ?? this.inkLight,
      inkFaint: inkFaint ?? this.inkFaint,
      primaryLight: primaryLight ?? this.primaryLight,
      accentLight: accentLight ?? this.accentLight,
      successLight: successLight ?? this.successLight,
      dangerLight: dangerLight ?? this.dangerLight,
      primaryInk: primaryInk ?? this.primaryInk,
      accentInk: accentInk ?? this.accentInk,
      successInk: successInk ?? this.successInk,
      dangerInk: dangerInk ?? this.dangerInk,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMid: Color.lerp(inkMid, other.inkMid, t)!,
      inkLight: Color.lerp(inkLight, other.inkLight, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      dangerLight: Color.lerp(dangerLight, other.dangerLight, t)!,
      primaryInk: Color.lerp(primaryInk, other.primaryInk, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      successInk: Color.lerp(successInk, other.successInk, t)!,
      dangerInk: Color.lerp(dangerInk, other.dangerInk, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// Resolves the active [AppPalette] for the current theme.
extension AppColorsX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
