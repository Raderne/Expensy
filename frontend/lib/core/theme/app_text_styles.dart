import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// DM Sans-based text styles. Sizes & weights mirror the design source.
@immutable
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _base({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  // Display / hero
  static TextStyle heroAmount = _base(
    size: 36,
    weight: FontWeight.w700,
    color: AppColors.surface,
    letterSpacing: -0.5,
  );

  static TextStyle addAmount = _base(
    size: 52,
    weight: FontWeight.w700,
    letterSpacing: -2,
  );

  // Titles
  static TextStyle titleL = _base(size: 22, weight: FontWeight.w700);
  static TextStyle titleM = _base(size: 18, weight: FontWeight.w700);
  static TextStyle titleS = _base(size: 15, weight: FontWeight.w700);

  // Body
  static TextStyle body = _base(size: 14, color: AppColors.inkMid);
  static TextStyle bodyStrong = _base(size: 14, weight: FontWeight.w600);

  // Labels
  static TextStyle label = _base(size: 13, weight: FontWeight.w500);
  static TextStyle labelStrong = _base(size: 13, weight: FontWeight.w700);

  // Muted (table headers, captions, status bar)
  static TextStyle muted = _base(size: 12, color: AppColors.inkLight);
  static TextStyle mutedSmall = _base(size: 11, color: AppColors.inkLight);

  // Uppercase group label (TODAY / YESTERDAY / MAY 21)
  static TextStyle groupLabel = _base(
    size: 11,
    weight: FontWeight.w700,
    color: AppColors.inkLight,
    letterSpacing: 1.2,
  );
}
