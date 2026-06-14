import 'package:flutter/foundation.dart' hide Category;

import '../../../core/models/category.dart';

@immutable
class Transaction {
  final String id;
  final double amount;
  final String? note;
  final DateTime occurredAt;
  final Category category;
  final String? recurringIncomeId;

  /// `true` for an optimistic row still waiting in the outbox to reach the
  /// server. Defaults to `false` and is never serialized from the API.
  final bool pending;

  const Transaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.occurredAt,
    required this.category,
    this.recurringIncomeId,
    this.pending = false,
  });

  bool get isRecurringIncome => recurringIncomeId != null;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    note: json['note'] as String?,
    occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
    category: Category.fromJson(json['category'] as Map<String, dynamic>),
    recurringIncomeId: json['recurringIncomeId'] as String?,
  );
}
