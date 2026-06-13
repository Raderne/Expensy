import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

@immutable
class BreakdownItem {
  final String categoryId;
  final String key;
  final String label;
  final String color;
  final double amount;
  final double pct; // 0..1

  const BreakdownItem({
    required this.categoryId,
    required this.key,
    required this.label,
    required this.color,
    required this.amount,
    required this.pct,
  });

  factory BreakdownItem.fromJson(Map<String, dynamic> json) => BreakdownItem(
    categoryId: json['categoryId'] as String,
    key: json['key'] as String,
    label: json['label'] as String,
    color: json['color'] as String,
    amount: (json['amount'] as num).toDouble(),
    pct: (json['pct'] as num).toDouble(),
  );

  /// System categories take their palette from the static map; custom ones
  /// fall back to the backend-provided hex (and a derived wash for the tint).
  Color get colorValue =>
      AppColors.categories[key]?.color ??
      _safeHex(color) ??
      const Color(0xFF96A5BE);

  Color get bgTintValue =>
      AppColors.categories[key]?.bgTint ??
      _safeHex(color)?.withValues(alpha: 0.14) ??
      const Color(0xFFEEF3FF);

  static Color? _safeHex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.isEmpty) return null;
    final value = int.tryParse('FF$clean', radix: 16);
    return value == null ? null : Color(value);
  }
}

@immutable
class AnalyticsBreakdown {
  final String month;
  final double total;
  final List<BreakdownItem> items;

  const AnalyticsBreakdown({
    required this.month,
    required this.total,
    required this.items,
  });

  bool get isEmpty => items.isEmpty || total == 0;

  factory AnalyticsBreakdown.fromJson(Map<String, dynamic> json) =>
      AnalyticsBreakdown(
        month: json['month'] as String,
        total: (json['total'] as num).toDouble(),
        items: (json['breakdown'] as List<dynamic>)
            .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
