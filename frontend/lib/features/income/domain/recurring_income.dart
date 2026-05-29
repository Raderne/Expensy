import 'package:flutter/foundation.dart';

@immutable
class RecurringIncome {
  final String id;
  final String label;
  final double amount;
  final int dayOfMonth;
  final bool isActive;

  const RecurringIncome({
    required this.id,
    required this.label,
    required this.amount,
    required this.dayOfMonth,
    required this.isActive,
  });

  factory RecurringIncome.fromJson(Map<String, dynamic> json) => RecurringIncome(
        id: json['id'] as String,
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        dayOfMonth: (json['dayOfMonth'] as num).toInt(),
        isActive: json['isActive'] as bool? ?? true,
      );
}
