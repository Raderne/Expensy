import 'package:flutter/foundation.dart';

enum OccurrenceType { income, expense }

/// A due recurring income/expense awaiting the user's confirm-or-postpone
/// decision. Mirrors the backend `PendingOccurrenceDto`.
@immutable
class PendingOccurrence {
  final String id;
  final OccurrenceType type;
  final String label;

  /// Always positive; the sign is implied by [type].
  final double amount;

  /// The canonical schedule day this occurrence belongs to (never changes on
  /// postpone). Shown to the user as "due on …".
  final DateTime scheduledFor;

  /// When the prompt is currently due (moves forward on postpone).
  final DateTime dueAt;

  final String categoryKey;
  final String categoryColor;

  const PendingOccurrence({
    required this.id,
    required this.type,
    required this.label,
    required this.amount,
    required this.scheduledFor,
    required this.dueAt,
    required this.categoryKey,
    required this.categoryColor,
  });

  bool get isIncome => type == OccurrenceType.income;

  factory PendingOccurrence.fromJson(Map<String, dynamic> json) =>
      PendingOccurrence(
        id: json['id'] as String,
        type: (json['type'] as String) == 'income'
            ? OccurrenceType.income
            : OccurrenceType.expense,
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        dueAt: DateTime.parse(json['dueAt'] as String),
        categoryKey: json['categoryKey'] as String? ?? '',
        categoryColor: json['categoryColor'] as String? ?? '',
      );
}
