import 'package:flutter/foundation.dart';

enum RecurrenceFrequency { weekly, biweekly, monthly, custom }

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get wireValue => switch (this) {
        RecurrenceFrequency.weekly => 'WEEKLY',
        RecurrenceFrequency.biweekly => 'BIWEEKLY',
        RecurrenceFrequency.monthly => 'MONTHLY',
        RecurrenceFrequency.custom => 'CUSTOM',
      };

  String get label => switch (this) {
        RecurrenceFrequency.weekly => 'Weekly',
        RecurrenceFrequency.biweekly => 'Biweekly',
        RecurrenceFrequency.monthly => 'Monthly',
        RecurrenceFrequency.custom => 'Custom',
      };

  static RecurrenceFrequency fromWire(String value) => switch (value) {
        'WEEKLY' => RecurrenceFrequency.weekly,
        'BIWEEKLY' => RecurrenceFrequency.biweekly,
        'MONTHLY' => RecurrenceFrequency.monthly,
        'CUSTOM' => RecurrenceFrequency.custom,
        _ => throw ArgumentError('Unknown frequency: $value'),
      };
}

@immutable
class RecurringExpense {
  final String id;
  final String label;
  final double amount;
  final String categoryId;
  final String categoryKey;
  final String categoryLabel;
  final String categoryColor;
  final RecurrenceFrequency frequency;
  final int? intervalDays;
  final DateTime anchorDate;
  final bool isActive;

  const RecurringExpense({
    required this.id,
    required this.label,
    required this.amount,
    required this.categoryId,
    required this.categoryKey,
    required this.categoryLabel,
    required this.categoryColor,
    required this.frequency,
    required this.intervalDays,
    required this.anchorDate,
    required this.isActive,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) => RecurringExpense(
        id: json['id'] as String,
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as String,
        categoryKey: json['categoryKey'] as String,
        categoryLabel: json['categoryLabel'] as String,
        categoryColor: json['categoryColor'] as String,
        frequency: RecurrenceFrequencyX.fromWire(json['frequency'] as String),
        intervalDays: (json['intervalDays'] as num?)?.toInt(),
        anchorDate: DateTime.parse(json['anchorDate'] as String).toLocal(),
        isActive: json['isActive'] as bool? ?? true,
      );
}
