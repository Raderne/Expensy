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

  /// Portion of this expense owed by other people (0 when not split). Lets the
  /// list show a "you're owed X" badge.
  final double sharedOwedTotal;

  /// True when this positive row is a contact's repayment, not real income.
  final bool isReimbursement;

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
    this.sharedOwedTotal = 0,
    this.isReimbursement = false,
    this.pending = false,
  });

  bool get isRecurringIncome => recurringIncomeId != null;

  /// True when others share this expense.
  bool get isShared => sharedOwedTotal > 0;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    note: json['note'] as String?,
    // Transaction dates are pure calendar dates pinned to UTC midnight; read
    // them back in UTC (not local) so day/month grouping matches the day the
    // user picked regardless of their timezone.
    occurredAt: DateTime.parse(json['occurredAt'] as String).toUtc(),
    category: Category.fromJson(json['category'] as Map<String, dynamic>),
    recurringIncomeId: json['recurringIncomeId'] as String?,
    sharedOwedTotal: (json['sharedOwedTotal'] as num?)?.toDouble() ?? 0,
    isReimbursement: json['isReimbursement'] as bool? ?? false,
  );
}
