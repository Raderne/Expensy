import 'package:expensy/core/models/category.dart';
import 'package:expensy/features/transactions/domain/date_grouping.dart';
import 'package:expensy/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cat = Category(
    id: 'c1',
    key: 'food',
    label: 'Food',
    abbr: 'FD',
    color: '#F56B1E',
    bgTint: '#FEF0E8',
  );

  Transaction tx(String id, DateTime when) => Transaction(
        id: id,
        amount: -12.5,
        note: null,
        occurredAt: when,
        category: cat,
      );

  test('empty input → empty list', () {
    expect(groupByDay([]), isEmpty);
  });

  test('labels today and yesterday', () {
    final now = DateTime(2026, 5, 28, 14, 0);
    final groups = groupByDay(
      [
        tx('a', DateTime(2026, 5, 28, 10)),
        tx('b', DateTime(2026, 5, 27, 9)),
      ],
      now: now,
    );
    expect(groups.length, 2);
    expect(groups[0].label, 'TODAY');
    expect(groups[1].label, 'YESTERDAY');
  });

  test('uses MMM d for older days, uppercased', () {
    final now = DateTime(2026, 5, 28);
    final groups = groupByDay(
      [tx('a', DateTime(2026, 5, 21, 9))],
      now: now,
    );
    expect(groups.single.label, 'MAY 21');
  });

  test('multiple rows on same day land in one group', () {
    final now = DateTime(2026, 5, 28, 14);
    final groups = groupByDay(
      [
        tx('a', DateTime(2026, 5, 28, 13)),
        tx('b', DateTime(2026, 5, 28, 9)),
        tx('c', DateTime(2026, 5, 27, 22)),
      ],
      now: now,
    );
    expect(groups.length, 2);
    expect(groups[0].label, 'TODAY');
    expect(groups[0].transactions.length, 2);
    expect(groups[1].label, 'YESTERDAY');
    expect(groups[1].transactions.single.id, 'c');
  });
}
