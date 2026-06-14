import 'package:expensy/features/recurring_expenses/domain/recurrence.dart';
import 'package:expensy/features/recurring_expenses/domain/recurring_expense.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringExpense _rule({
  required RecurrenceFrequency frequency,
  required DateTime anchorDate,
  int? intervalDays,
}) => RecurringExpense(
  id: 'r',
  label: 'Test',
  amount: 10,
  categoryId: 'c',
  categoryKey: 'subscriptions',
  categoryLabel: 'Subs',
  categoryColor: '#8B5CF6',
  frequency: frequency,
  intervalDays: intervalDays,
  anchorDate: anchorDate,
  isActive: true,
);

void main() {
  group('weekly', () {
    final rule = _rule(
      frequency: RecurrenceFrequency.weekly,
      anchorDate: DateTime(2026, 5, 1),
    );

    test('upcoming walks anchor + 7 days', () {
      final out = upcomingOccurrences(rule, DateTime(2026, 5, 1), 3);
      expect(out, [
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 8),
        DateTime(2026, 5, 15),
      ]);
    });

    test('next is strictly after cutoff', () {
      expect(nextOccurrence(rule, DateTime(2026, 5, 8)), DateTime(2026, 5, 15));
    });
  });

  group('biweekly', () {
    final rule = _rule(
      frequency: RecurrenceFrequency.biweekly,
      anchorDate: DateTime(2026, 5, 5),
    );

    test('walks by 14 days', () {
      expect(upcomingOccurrences(rule, DateTime(2026, 5, 5), 3), [
        DateTime(2026, 5, 5),
        DateTime(2026, 5, 19),
        DateTime(2026, 6, 2),
      ]);
    });
  });

  group('monthly', () {
    test('clamps Jan 31 -> Feb 28 in non-leap years', () {
      final rule = _rule(
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2026, 1, 31),
      );
      expect(upcomingOccurrences(rule, DateTime(2026, 1, 31), 3), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
      ]);
    });

    test('clamps Jan 31 -> Feb 29 in a leap year', () {
      final rule = _rule(
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2024, 1, 31),
      );
      expect(upcomingOccurrences(rule, DateTime(2024, 1, 31), 2), [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29),
      ]);
    });

    test('honors a from-date mid-sequence', () {
      final rule = _rule(
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2026, 1, 15),
      );
      expect(upcomingOccurrences(rule, DateTime(2026, 3, 20), 2), [
        DateTime(2026, 4, 15),
        DateTime(2026, 5, 15),
      ]);
    });
  });

  group('custom', () {
    final rule = _rule(
      frequency: RecurrenceFrequency.custom,
      anchorDate: DateTime(2026, 1, 1),
      intervalDays: 45,
    );

    test('walks by intervalDays', () {
      expect(upcomingOccurrences(rule, DateTime(2026, 1, 1), 3), [
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 15),
        DateTime(2026, 4, 1),
      ]);
    });

    test('throws when intervalDays missing', () {
      final broken = _rule(
        frequency: RecurrenceFrequency.custom,
        anchorDate: DateTime(2026, 1, 1),
      );
      expect(
        () => upcomingOccurrences(broken, DateTime(2026, 1, 1), 1),
        throwsArgumentError,
      );
    });
  });
}
