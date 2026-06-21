import 'package:flutter/material.dart';

/// Theme-variant design tokens — every color that differs between Light and Dark
/// lives here and is resolved per [BuildContext] via `context.colors`.
///
/// Brand-invariant colors (primary, accent, success, danger, the category
/// palette) stay as `static const` in [AppColors]. The rule for contributors:
/// brand colors → `AppColors.*`; surfaces / text / tints / shadows / glass →
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
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassBlur,
    required this.ambientOpacity,
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

  // Glassmorphism — frosted-glass surface tokens consumed by `GlassCard`.
  // [glassFill] is the translucent body wash; [glassFillStrong] is a denser
  // variant for cards that need more legibility (e.g. transaction ledgers).
  // [glassBorder] is the hairline inner border; [glassHighlight] is the soft
  // top sheen. [glassBlur] is the BackdropFilter sigma. [ambientOpacity] scales
  // the colored glow blobs painted by `AmbientBackground` (dimmed in Light so
  // the wash doesn't muddy a bright background).
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassHighlight;
  final double glassBlur;
  final double ambientOpacity;

  /// Light theme — frosted white glass over a soft blue-tinted background.
  static const light = AppPalette(
    background: Color(0xFFEAF0FF),
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
    shadow: Color(0x14000C22),
    scrim: Color(0x66000C22),
    shimmerBase: Color(0xFFD5DDF0),
    shimmerHighlight: Color(0xFFECF1FA),
    glassFill: Color(0xCCFFFFFF),
    glassFillStrong: Color(0xF2FFFFFF),
    glassBorder: Color(0xCCFFFFFF),
    glassHighlight: Color(0x66FFFFFF),
    glassBlur: 18,
    ambientOpacity: 0.35,
  );

  /// Dark theme — frosted glass over deep charcoal with ambient blue/orange
  /// glow. This is the signature glassmorphic look.
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
    shadow: Color(0x59000000),
    scrim: Color(0x99000000),
    shimmerBase: Color(0xFF1E2538),
    shimmerHighlight: Color(0xFF283047),
    glassFill: Color(0x14FFFFFF),
    glassFillStrong: Color(0x1FFFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassHighlight: Color(0x14FFFFFF),
    glassBlur: 18,
    ambientOpacity: 1.0,
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
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassHighlight,
    double? glassBlur,
    double? ambientOpacity,
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
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassBlur: glassBlur ?? this.glassBlur,
      ambientOpacity: ambientOpacity ?? this.ambientOpacity,
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
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t),
      ambientOpacity: lerpDouble(ambientOpacity, other.ambientOpacity, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Resolves the active [AppPalette] for the current theme.
extension AppColorsX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
