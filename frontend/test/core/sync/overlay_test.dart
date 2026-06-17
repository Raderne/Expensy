import 'package:expensy/core/data/categories_repository.dart';
import 'package:expensy/core/models/category.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:expensy/features/dashboard/application/dashboard_controller.dart';
import 'package:expensy/features/dashboard/domain/dashboard_summary.dart';
import 'package:expensy/features/dashboard/domain/recent_transaction.dart';
import 'package:expensy/features/transactions/application/transactions_controller.dart';
import 'package:expensy/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, {bool pending = false}) => Category(
  id: id,
  key: id,
  label: 'Cat $id',
  abbr: 'C',
  color: '#111111',
  bgTint: '#222222',
  isSystem: false,
  pending: pending,
);

OutboxEntry _txCreate({
  required String tempId,
  required String categoryId,
  required double amount,
  required String occurredAtIso,
}) => OutboxEntry(
  id: 'e-$tempId',
  createdAt: 1,
  kind: 'txCreate',
  method: 'POST',
  path: '/transactions',
  idempotencyKey: 'k-$tempId',
  tempId: tempId,
  body: {
    'categoryId': categoryId,
    'amount': amount,
    'occurredAt': occurredAtIso,
  },
);

OutboxEntry _txDelete(String id) => OutboxEntry(
  id: 'd-$id',
  createdAt: 2,
  kind: 'txDelete',
  method: 'DELETE',
  path: '/transactions/$id',
  idempotencyKey: 'k-$id',
);

OutboxEntry _catCreate(String tempId, {String label = 'New'}) => OutboxEntry(
  id: 'ce-$tempId',
  createdAt: 3,
  kind: 'categoryCreate',
  method: 'POST',
  path: '/categories',
  idempotencyKey: 'k-$tempId',
  tempId: tempId,
  body: {'label': label, 'abbr': 'NW', 'color': '#abcdef'},
);

void main() {
  group('overlayCategories', () {
    test('appends pending creates and hides queued deletes', () {
      final base = [_cat('sys1'), _cat('sys2')];
      final result = overlayCategories(base, [
        _catCreate('tmp1', label: 'Coffee'),
        const OutboxEntry(
          id: 'del',
          createdAt: 4,
          kind: 'categoryDelete',
          method: 'DELETE',
          path: '/categories/sys2',
          idempotencyKey: 'k',
        ),
      ]);

      expect(result.map((c) => c.id), ['sys1', 'tmp1']);
      final created = result.firstWhere((c) => c.id == 'tmp1');
      expect(created.label, 'Coffee');
      expect(created.pending, isTrue);
    });

    test('returns the base list unchanged when nothing is pending', () {
      final base = [_cat('a')];
      expect(overlayCategories(base, const []), same(base));
    });
  });

  group('overlayTransactions', () {
    TransactionsState baseState({
      List<Transaction> txns = const [],
      double income = 1000,
      double expenses = 200,
      String month = '2026-06',
      TransactionFilters filters = TransactionFilters.none,
    }) => TransactionsState(
      month: month,
      transactions: txns,
      nextCursor: null,
      availableMonths: const ['2026-06'],
      income: income,
      expenses: expenses,
      net: income - expenses,
      filters: filters,
    );

    test('prepends a pending expense and grows the expense total', () {
      final result = overlayTransactions(
        baseState(),
        [
          _txCreate(
            tempId: 'tmp1',
            categoryId: 'c1',
            amount: 50,
            occurredAtIso: '2026-06-10T12:00:00Z',
          ),
        ],
        [_cat('c1')],
      );

      expect(result.transactions.first.pending, isTrue);
      expect(result.transactions.first.amount, -50); // stored negative
      expect(result.expenses, 250);
      expect(result.net, 1000 - 250);
    });

    test('excludes pending creates outside the active month', () {
      final result = overlayTransactions(
        baseState(month: '2026-06'),
        [
          _txCreate(
            tempId: 'tmp1',
            categoryId: 'c1',
            amount: 50,
            occurredAtIso: '2026-05-10T12:00:00Z',
          ),
        ],
        [_cat('c1')],
      );
      expect(result.transactions, isEmpty);
      expect(result.expenses, 200);
    });

    test('respects an active category filter', () {
      final result = overlayTransactions(
        baseState(filters: const TransactionFilters(categoryId: 'other')),
        [
          _txCreate(
            tempId: 'tmp1',
            categoryId: 'c1',
            amount: 50,
            occurredAtIso: '2026-06-10T12:00:00Z',
          ),
        ],
        [_cat('c1')],
      );
      expect(result.transactions, isEmpty);
    });

    test('hides a queued delete and reverses its expense contribution', () {
      final existing = Transaction(
        id: 'x1',
        amount: -30,
        note: null,
        occurredAt: DateTime(2026, 6, 5),
        category: _cat('c1'),
      );
      final result = overlayTransactions(
        baseState(txns: [existing], expenses: 200),
        [_txDelete('x1')],
        [_cat('c1')],
      );
      expect(result.transactions, isEmpty);
      expect(result.expenses, 170); // 200 - 30
    });
  });

  group('overlayDashboard', () {
    DashboardState base({
      List<RecentTransaction> recent = const [],
      double income = 1000,
      double expenses = 200,
      double balance = 800,
      double budgetAmount = 400,
      double spent = 200,
    }) => DashboardState(
      summary: DashboardSummary(
        balance: balance,
        net: income - expenses,
        income: income,
        expenses: expenses,
        budget: BudgetInfo(
          amount: budgetAmount,
          spent: spent,
          pct: budgetAmount > 0 ? (spent / budgetAmount * 100).round() : 0,
        ),
      ),
      recentTransactions: recent,
      month: '2026-06',
    );

    test('folds a pending expense into totals and budget', () {
      final result = overlayDashboard(
        base(),
        [
          _txCreate(
            tempId: 'tmp1',
            categoryId: 'c1',
            amount: 100,
            occurredAtIso: '2026-06-10T12:00:00Z',
          ),
        ],
        [_cat('c1')],
      );

      expect(result.recentTransactions.first.pending, isTrue);
      expect(result.summary.expenses, 300);
      expect(result.summary.balance, 700);
      expect(result.summary.budget.spent, 300);
      expect(result.summary.budget.pct, 75); // 300/400
      expect(result.summary.net, 1000 - 300);
    });

    test('reverses a deleted expense present in the recent list', () {
      final recent = RecentTransaction(
        id: 'r1',
        amount: -40,
        note: null,
        occurredAt: DateTime(2026, 6, 1),
        category: _cat('c1'),
      );
      final result = overlayDashboard(
        base(recent: [recent], expenses: 200, balance: 800, spent: 200),
        [_txDelete('r1')],
        [_cat('c1')],
      );
      expect(result.recentTransactions, isEmpty);
      expect(result.summary.expenses, 160);
      expect(result.summary.balance, 840);
      expect(result.summary.budget.spent, 160);
    });
  });
}
