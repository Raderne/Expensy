import 'package:flutter/foundation.dart';

import '../../recurring_confirmations/domain/postponed_info.dart';

@immutable
class RecurringIncome {
  final String id;
  final String label;
  final double amount;
  final int dayOfMonth;
  final bool isActive;

  /// Set when this rule has an actively-postponed occurrence for the cycle.
  final PostponedInfo? postponed;

  const RecurringIncome({
    required this.id,
    required this.label,
    required this.amount,
    required this.dayOfMonth,
    required this.isActive,
    this.postponed,
  });

  factory RecurringIncome.fromJson(Map<String, dynamic> json) =>
      RecurringIncome(
        id: json['id'] as String,
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        dayOfMonth: (json['dayOfMonth'] as num).toInt(),
        isActive: json['isActive'] as bool? ?? true,
        postponed: json['postponed'] == null
            ? null
            : PostponedInfo.fromJson(json['postponed'] as Map<String, dynamic>),
      );
}
