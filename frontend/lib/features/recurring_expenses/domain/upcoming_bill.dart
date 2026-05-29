import 'package:flutter/foundation.dart';

@immutable
class UpcomingBill {
  final String ruleId;
  final String label;
  final double amount;
  final DateTime occurredAt;
  final String categoryId;
  final String categoryKey;
  final String categoryColor;

  const UpcomingBill({
    required this.ruleId,
    required this.label,
    required this.amount,
    required this.occurredAt,
    required this.categoryId,
    required this.categoryKey,
    required this.categoryColor,
  });

  factory UpcomingBill.fromJson(Map<String, dynamic> json) => UpcomingBill(
        ruleId: json['ruleId'] as String,
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
        categoryId: json['categoryId'] as String,
        categoryKey: json['categoryKey'] as String,
        categoryColor: json['categoryColor'] as String,
      );
}
