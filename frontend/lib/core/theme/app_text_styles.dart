import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// DM Sans-based text styles. Sizes & weights mirror the design source.
///
/// These are getters (not const fields) so theme-variant colors resolve against
/// the active palette on every access — a `Text(style: AppTextStyles.body)`
/// picks up the right ink color in Light and Dark.
@immutable
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _base({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.ink,
    height: height,
    letterSpacing: letterSpacing,
  );

  // Display / hero — sits on the blue hero gradient, so it stays white in
  // every theme.
  static TextStyle get heroAmount => _base(
    size: 36,
    weight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static TextStyle get addAmount =>
      _base(size: 52, weight: FontWeight.w700, letterSpacing: -2);

  // Titles
  static TextStyle get titleL => _base(size: 22, weight: FontWeight.w700);
  static TextStyle get titleM => _base(size: 18, weight: FontWeight.w700);
  static TextStyle get titleS => _base(size: 15, weight: FontWeight.w700);

  // Body
  static TextStyle get body => _base(size: 14, color: AppColors.inkMid);
  static TextStyle get bodyStrong => _base(size: 14, weight: FontWeight.w600);

  // Labels
  static TextStyle get label => _base(size: 13, weight: FontWeight.w500);
  static TextStyle get labelStrong => _base(size: 13, weight: FontWeight.w700);

  // Muted (table headers, captions, status bar)
  static TextStyle get muted => _base(size: 12, color: AppColors.inkLight);
  static TextStyle get mutedSmall => _base(size: 11, color: AppColors.inkLight);

  // Uppercase group label (TODAY / YESTERDAY / MAY 21)
  static TextStyle get groupLabel => _base(
    size: 11,
    weight: FontWeight.w700,
    color: AppColors.inkLight,
    letterSpacing: 1.2,
  );
}
