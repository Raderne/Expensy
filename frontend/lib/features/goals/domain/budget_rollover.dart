import 'package:flutter/foundation.dart';

/// A finished month's leftover budget that the user can still move into savings
/// goals. `remaining` = amount − spent − already-allocated.
@immutable
class BudgetRollover {
  final String month; // YYYY-MM
  final double amount;
  final double spent;
  final double remaining;

  const BudgetRollover({
    required this.month,
    required this.amount,
    required this.spent,
    required this.remaining,
  });

  factory BudgetRollover.fromJson(Map<String, dynamic> json) => BudgetRollover(
    month: json['month'] as String,
    amount: (json['amount'] as num).toDouble(),
    spent: (json['spent'] as num).toDouble(),
    remaining: (json['remaining'] as num).toDouble(),
  );

  /// Parses the `YYYY-MM` month into a `DateTime` (day 1) for label formatting.
  DateTime get monthDate {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }
}
