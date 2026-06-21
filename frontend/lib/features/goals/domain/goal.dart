import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'goal_icons.dart';

@immutable
class Goal {
  final String id;
  final String name;
  final String icon;

  /// Hex color (e.g. `#1B45D0`), chosen from the shared category palette.
  final String color;
  final double targetAmount;
  final double savedAmount;

  /// Optional target date (date-only); drives [monthlyContribution].
  final DateTime? targetDate;

  const Goal({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.targetAmount,
    required this.savedAmount,
    this.targetDate,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? kDefaultGoalIcon,
    color: json['color'] as String? ?? '#1B45D0',
    targetAmount: (json['targetAmount'] as num).toDouble(),
    savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
    targetDate: json['targetDate'] == null
        ? null
        : DateTime.parse(json['targetDate'] as String).toLocal(),
  );

  /// Fraction saved, clamped to 0..1 (a goal can be over-funded).
  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  int get pct => (progress * 100).round();

  bool get isComplete => targetAmount > 0 && savedAmount >= targetAmount;

  double get remaining => math.max(0, targetAmount - savedAmount);

  IconData get iconData => goalIconData(icon);

  Color get colorValue => _parseHex(color) ?? const Color(0xFF1B45D0);

  /// Suggested monthly contribution to hit [targetAmount] by [targetDate].
  /// Returns 0 when there's no future date or the goal is already met.
  double get monthlyContribution {
    final date = targetDate;
    if (date == null || remaining <= 0) return 0;
    final days = date.difference(DateTime.now()).inDays;
    if (days <= 0) return 0;
    final monthsRemaining = math.max(1, (days / 30).ceil());
    return remaining / monthsRemaining;
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    final v = int.tryParse(clean, radix: 16);
    if (v == null) return null;
    return Color(clean.length == 6 ? 0xFF000000 | v : v);
  }
}

extension GoalsX on List<Goal> {
  double get totalSaved => fold(0.0, (sum, g) => sum + g.savedAmount);
  double get totalTarget => fold(0.0, (sum, g) => sum + g.targetAmount);
  double get monthlySavings =>
      fold(0.0, (sum, g) => sum + g.monthlyContribution);
}
