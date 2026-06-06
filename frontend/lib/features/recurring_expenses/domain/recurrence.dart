import 'recurring_expense.dart';

/// Pure cadence math for the frontend. Mirrors backend `src/lib/recurrence.ts`
/// so the next-occurrence label we render lines up with what the server will
/// materialize. No I/O — easy to test.

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

// `month` is 1-based (Jan = 1).
int _lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _addMonthsClamped(DateTime d, int months) {
  final zeroBased = (d.month - 1) + months;
  final year =
      d.year +
      (zeroBased ~/ 12) -
      (zeroBased < 0 && zeroBased % 12 != 0 ? 1 : 0);
  final month = (((zeroBased % 12) + 12) % 12) + 1; // 1-based target month
  final last = _lastDayOfMonth(year, month);
  final day = d.day <= last ? d.day : last;
  return DateTime(year, month, day);
}

int _stepDays(RecurrenceFrequency f, int? intervalDays) {
  switch (f) {
    case RecurrenceFrequency.weekly:
      return 7;
    case RecurrenceFrequency.biweekly:
      return 14;
    case RecurrenceFrequency.custom:
      if (intervalDays == null || intervalDays < 1) {
        throw ArgumentError('intervalDays required for CUSTOM frequency');
      }
      return intervalDays;
    case RecurrenceFrequency.monthly:
      return 0;
  }
}

DateTime occurrenceAt(RecurringExpense rule, int k) {
  final anchor = _startOfDay(rule.anchorDate);
  if (rule.frequency == RecurrenceFrequency.monthly) {
    return _addMonthsClamped(anchor, k);
  }
  return _addDays(anchor, _stepDays(rule.frequency, rule.intervalDays) * k);
}

int _firstIndexOnOrAfter(RecurringExpense rule, DateTime target) {
  final anchor = _startOfDay(rule.anchorDate);
  final cutoff = _startOfDay(target);
  if (!anchor.isBefore(cutoff)) return 0;

  if (rule.frequency == RecurrenceFrequency.monthly) {
    final estimate =
        (cutoff.year - anchor.year) * 12 + (cutoff.month - anchor.month);
    var k = estimate - 1 < 0 ? 0 : estimate - 1;
    while (occurrenceAt(rule, k).isBefore(cutoff)) {
      k += 1;
    }
    return k;
  }

  final step = _stepDays(rule.frequency, rule.intervalDays);
  final diffDays = cutoff.difference(anchor).inDays;
  return (diffDays / step).ceil();
}

DateTime nextOccurrence(RecurringExpense rule, DateTime after) {
  final cutoff = _startOfDay(after);
  var k = _firstIndexOnOrAfter(rule, cutoff);
  if (!occurrenceAt(rule, k).isAfter(cutoff)) k += 1;
  return occurrenceAt(rule, k);
}

/// Next [limit] occurrences with start-of-day >= [from].
List<DateTime> upcomingOccurrences(
  RecurringExpense rule,
  DateTime from,
  int limit,
) {
  if (limit <= 0) return const [];
  var k = _firstIndexOnOrAfter(rule, from);
  final out = <DateTime>[];
  while (out.length < limit) {
    out.add(occurrenceAt(rule, k));
    k += 1;
  }
  return out;
}
