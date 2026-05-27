import 'package:flutter/material.dart';

/// Design tokens mirroring `design/Expensy.html` theme object `T`.
/// Treat this as the single source of truth; never hard-code hex in widgets.
@immutable
class AppColors {
  const AppColors._();

  // Primary (blue)
  static const Color primary = Color(0xFF1B45D0);
  static const Color primaryDark = Color(0xFF0C228E);
  static const Color primaryLight = Color(0xFFE8EFFE);

  // Accent (orange)
  static const Color accent = Color(0xFFF56B1E);
  static const Color accentLight = Color(0xFFFEF0E8);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Surfaces
  static const Color background = Color(0xFFEEF3FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDE6FF);

  // Ink (text)
  static const Color ink = Color(0xFF0C1530);
  static const Color inkMid = Color(0xFF4A5675);
  static const Color inkLight = Color(0xFF96A5BE);
  static const Color inkFaint = Color(0xFFD5DDF0);

  // Category palette (key, color, bgTint)
  static const Map<String, CategoryColor> categories = {
    'food': CategoryColor(Color(0xFFF56B1E), Color(0xFFFEF0E8)),
    'travel': CategoryColor(Color(0xFF1B45D0), Color(0xFFE8EFFE)),
    'shop': CategoryColor(Color(0xFF7C3AED), Color(0xFFEDE9FE)),
    'health': CategoryColor(Color(0xFF16A34A), Color(0xFFDCFCE7)),
    'fun': CategoryColor(Color(0xFFDB2777), Color(0xFFFCE7F3)),
    'home': CategoryColor(Color(0xFF0891B2), Color(0xFFCFFAFE)),
  };
}

@immutable
class CategoryColor {
  final Color color;
  final Color bgTint;
  const CategoryColor(this.color, this.bgTint);
}
