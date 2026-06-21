import 'package:expensy/features/recurring_expenses/application/recurring_expenses_controller.dart';
import 'package:expensy/features/recurring_expenses/domain/recurring_expense.dart';
import 'package:expensy/features/shared/domain/recurring_share_draft.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringExpense _rule({
  required double amount,
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  int? intervalDays,
  bool isActive = true,
  List<RecurringShareDraft> shares = const [],
}) => RecurringExpense(
  id: 'r',
  label: 'Test',
  amount: amount,
  categoryId: 'c',
  categoryKey: 'subscriptions',
  categoryLabel: 'Subs',
  categoryColor: '#8B5CF6',
  frequency: frequency,
  intervalDays: intervalDays,
  anchorDate: DateTime(2026, 5, 1),
  isActive: isActive,
  shares: shares,
);

RecurringShareDraft _pct(double value) =>
    RecurringShareDraft(contactId: 'x', shareType: ShareType.percent, shareValue: value);

void main() {
  group('activeMonthlyTotal', () {
    test('unshared rule counts the full amount', () {
      expect([_rule(amount: 100)].activeMonthlyTotal, 100);
    });

    test('counts only the user own share of a split bill', () {
      // $100 subscription + $300 bill split 50% → 100 + 150.
      final rules = [
        _rule(amount: 100),
        _rule(amount: 300, shares: [_pct(50)]),
      ];
      expect(rules.activeMonthlyTotal, 250);
    });

    test('non-50% split is respected', () {
      // 30% to a contact on a $300 bill → own share 210.
      expect([_rule(amount: 300, shares: [_pct(30)])].activeMonthlyTotal, 210);
    });

    test('fixed-amount share is subtracted as-is', () {
      expect(
        [
          _rule(
            amount: 100,
            shares: [
              const RecurringShareDraft(
                contactId: 'x',
                shareType: ShareType.amount,
                shareValue: 40,
              ),
            ],
          ),
        ].activeMonthlyTotal,
        60,
      );
    });

    test('normalizes the own share by frequency (weekly)', () {
      // Own share 50, weekly → 50 * 52 / 12.
      expect(
        [_rule(amount: 100, frequency: RecurrenceFrequency.weekly, shares: [_pct(50)])]
            .activeMonthlyTotal,
        closeTo(50 * 52 / 12, 1e-9),
      );
    });

    test('inactive rules are excluded', () {
      expect([_rule(amount: 100, isActive: false)].activeMonthlyTotal, 0);
    });
  });
}
