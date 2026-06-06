import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

@immutable
class Category {
  final String id;
  final String key;
  final String label;
  final String abbr;
  final String color;
  final String bgTint;
  final bool isSystem;

  const Category({
    required this.id,
    required this.key,
    required this.label,
    required this.abbr,
    required this.color,
    required this.bgTint,
    this.isSystem = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        // Transaction payloads historically omitted id; key is stable for UI theming.
        id: (json['id'] as String?) ?? json['key'] as String,
        key: json['key'] as String,
        label: json['label'] as String,
        abbr: json['abbr'] as String,
        color: json['color'] as String,
        bgTint: json['bgTint'] as String,
        isSystem: json['isSystem'] as bool? ?? true,
      );

  static Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  Color get colorValue =>
      AppColors.categories[key]?.color ?? _parseHex(color);

  Color get bgTintValue =>
      AppColors.categories[key]?.bgTint ?? _parseHex(bgTint);
}
