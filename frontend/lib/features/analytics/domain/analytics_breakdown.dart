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

  Color get colorValue =>
      AppColors.categories[key]?.color ?? const Color(0xFF96A5BE);

  Color get bgTintValue =>
      AppColors.categories[key]?.bgTint ?? const Color(0xFFEEF3FF);
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
