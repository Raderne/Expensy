import 'package:flutter/foundation.dart';

@immutable
class BudgetInfo {
  final double amount;
  final double spent;
  final int pct;

  const BudgetInfo({required this.amount, required this.spent, required this.pct});

  factory BudgetInfo.fromJson(Map<String, dynamic> json) => BudgetInfo(
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        pct: (json['pct'] as num).toInt(),
      );

  bool get isSet => amount > 0;
}

@immutable
class DashboardSummary {
  final double balance;
  final double net;
  final double income;
  final double expenses;
  final BudgetInfo budget;

  const DashboardSummary({
    required this.balance,
    required this.net,
    required this.income,
    required this.expenses,
    required this.budget,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        balance: (json['balance'] as num).toDouble(),
        net: (json['net'] as num?)?.toDouble() ??
            ((json['income'] as num).toDouble() - (json['expenses'] as num).toDouble()),
        income: (json['income'] as num).toDouble(),
        expenses: (json['expenses'] as num).toDouble(),
        budget: BudgetInfo.fromJson(json['budget'] as Map<String, dynamic>),
      );
}
