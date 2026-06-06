import 'package:flutter/foundation.dart' hide Category;

import '../../../core/models/category.dart';

@immutable
class RecentTransaction {
  final String id;
  final double amount;
  final String? note;
  final DateTime occurredAt;
  final Category category;

  const RecentTransaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.occurredAt,
    required this.category,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) =>
      RecentTransaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
      );
}
