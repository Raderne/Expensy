import 'package:flutter/material.dart';

/// The three Android home-screen widgets, each configured independently.
enum WidgetType {
  quickAdd,
  recent,
  budget;

  /// Key prefix shared with the Kotlin providers (e.g. `wcfg_quick_bg`).
  String get prefix => switch (this) {
    WidgetType.quickAdd => 'quick',
    WidgetType.recent => 'recent',
    WidgetType.budget => 'budget',
  };

  /// Kotlin AppWidgetProvider class simple name (for `updateWidget`).
  String get providerName => switch (this) {
    WidgetType.quickAdd => 'QuickAddWidgetProvider',
    WidgetType.recent => 'RecentTxWidgetProvider',
    WidgetType.budget => 'BudgetWidgetProvider',
  };

  String get label => switch (this) {
    WidgetType.quickAdd => 'Quick add',
    WidgetType.recent => 'Recent transactions',
    WidgetType.budget => 'Budget usage',
  };

  IconData get icon => switch (this) {
    WidgetType.quickAdd => Icons.add_circle_outline_rounded,
    WidgetType.recent => Icons.receipt_long_rounded,
    WidgetType.budget => Icons.donut_large_rounded,
  };
}

/// Whether the widget background is see-through or a filled card.
enum WidgetBgStyle {
  transparent,
  solid;

  String get wire => name; // 'transparent' | 'solid'
}

/// The base color the widget background and text adapt to.
enum WidgetColorMode {
  dark,
  light,
  matchPhone;

  /// Value written to the Kotlin side.
  String get wire => switch (this) {
    WidgetColorMode.dark => 'dark',
    WidgetColorMode.light => 'light',
    WidgetColorMode.matchPhone => 'match',
  };

  String get label => switch (this) {
    WidgetColorMode.dark => 'Dark',
    WidgetColorMode.light => 'Light',
    WidgetColorMode.matchPhone => 'Match phone',
  };
}

/// Per-widget appearance configuration.
@immutable
class WidgetAppearance {
  const WidgetAppearance({
    this.bg = WidgetBgStyle.solid,
    this.opacity = 85,
    this.color = WidgetColorMode.matchPhone,
  });

  /// Default for a freshly-added widget: match phone, solid, ~85% opacity.
  static const defaults = WidgetAppearance();

  final WidgetBgStyle bg;

  /// Background opacity, 0–100. Ignored when [bg] is [WidgetBgStyle.transparent].
  final int opacity;
  final WidgetColorMode color;

  WidgetAppearance copyWith({
    WidgetBgStyle? bg,
    int? opacity,
    WidgetColorMode? color,
  }) => WidgetAppearance(
    bg: bg ?? this.bg,
    opacity: opacity ?? this.opacity,
    color: color ?? this.color,
  );

  /// Compact pipe-encoded form for persistence: `solid|85|match`.
  String encode() => '${bg.name}|$opacity|${color.wire}';

  static WidgetAppearance decode(String? raw) {
    if (raw == null) return defaults;
    final parts = raw.split('|');
    if (parts.length != 3) return defaults;
    return WidgetAppearance(
      bg: WidgetBgStyle.values.firstWhere(
        (s) => s.name == parts[0],
        orElse: () => WidgetBgStyle.solid,
      ),
      opacity: int.tryParse(parts[1])?.clamp(0, 100) ?? 85,
      color: switch (parts[2]) {
        'dark' => WidgetColorMode.dark,
        'light' => WidgetColorMode.light,
        _ => WidgetColorMode.matchPhone,
      },
    );
  }
}
