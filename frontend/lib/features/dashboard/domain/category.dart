import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Category {
  final String key;
  final String label;
  final String abbr;
  final String color;
  final String bgTint;

  const Category({
    required this.key,
    required this.label,
    required this.abbr,
    required this.color,
    required this.bgTint,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        key: json['key'] as String,
        label: json['label'] as String,
        abbr: json['abbr'] as String,
        color: json['color'] as String,
        bgTint: json['bgTint'] as String,
      );

  Color get colorValue =>
      AppColors.categories[key]?.color ?? const Color(0xFF96A5BE);

  Color get bgTintValue =>
      AppColors.categories[key]?.bgTint ?? const Color(0xFFEEF3FF);
}
