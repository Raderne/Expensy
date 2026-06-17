import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/categories_repository.dart';
import '../../../core/models/category.dart';
import '../../../core/sync/outbox.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import '../domain/recent_transaction.dart';

class DashboardState {
  final DashboardSummary summary;
  final List<RecentTransaction> recentTransactions;
  final String month;

  const DashboardState({
    required this.summary,
    required this.recentTransactions,
    required this.month,
  });
}

String _currentMonth() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

class DashboardController extends AsyncNotifier<DashboardState> {
  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  static const _emptyState = DashboardState(
    summary: DashboardSummary(
      balance: 0,
      net: 0,
      income: 0,
      expenses: 0,
      budget: BudgetInfo(amount: 0, spent: 0, pct: 0),
    ),
    recentTransactions: [],
    month: '',
  );

  @override
  Future<DashboardState> build() async {
    // Depend on auth so this rebuilds on login/logout.
    final authAsync = ref.watch(authControllerProvider);
    if (!authAsync.hasValue || authAsync.value is! AuthAuthenticated) {
      return _emptyState;
    }

    final month = _currentMonth();

    // Stale-while-revalidate: if we have a cached snapshot, hand it back
    // immediately so the hero never flashes blank, then refresh in the
    // background and replace state when the network responds.
    final cached = await _loadFromCache(month);
    if (cached != null) {
      unawaited(_refreshSilently(month));
      return cached;
    }

    return _load(month);
  }

  Future<DashboardState?> _loadFromCache(String month) async {
    final summary = await _repo.readCachedSummary(month: month);
    final recent = await _repo.readCachedRecentTransactions(limit: 4);
    if (summary == null || recent == null) return null;
    return DashboardState(
      summary: summary,
      recentTransactions: recent,
      month: month,
    );
  }

  Future<DashboardState> _load(String month) async {
    final (summary, transactions) = await (
      _repo.getSummary(month: month),
      _repo.getRecentTransactions(limit: 4),
    ).wait;
    return DashboardState(
      summary: summary,
      recentTransactions: transactions,
      month: month,
    );
  }

  /// Background refresh after a cache hit. Swallows errors so a transient
  /// outage doesn't blow away the cached UI; the next pull-to-refresh will
  /// surface the failure if it persists.
  Future<void> _refreshSilently(String month) async {
    try {
      final fresh = await _load(month);
      state = AsyncData(fresh);
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard background refresh failed: $e');
    }
  }

  Future<void> refresh() async {
    final month = switch (state) {
      AsyncData(:final value) => value.month,
      _ => _currentMonth(),
    };
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(month));
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

RecentTransaction? _pendingRecentFrom(
  OutboxEntry e,
  List<Category> categories,
) {
  final body = e.body;
  if (body == null) return null;
  final categoryId = body['categoryId'] as String?;
  final amount = (body['amount'] as num?)?.toDouble();
  if (categoryId == null || amount == null) return null;
  Category? category;
  for (final c in categories) {
    if (c.id == categoryId) {
      category = c;
      break;
    }
  }
  if (category == null) return null;
  final occurredAtRaw = body['occurredAt'] as String?;
  final occurredAt = occurredAtRaw != null
      ? DateTime.parse(occurredAtRaw).toLocal()
      : DateTime.now();
  return RecentTransaction(
    id: e.tempId ?? e.id,
    amount: -amount, // expenses are stored negative server-side
    note: body['note'] as String?,
    occurredAt: occurredAt,
    category: category,
    pending: true,
  );
}

/// Overlays the dashboard with still-pending outbox writes: queued expense
/// creates are prepended to the recent list and folded into the month totals /
/// budget; queued deletes are hidden (and, when the row is in the recent list,
/// reversed out of the totals). Reconciles to canonical data on sync.
DashboardState overlayDashboard(
  DashboardState base,
  List<OutboxEntry> pending,
  List<Category> categories,
) {
  if (pending.isEmpty) return base;

  final deletedIds = <String>{
    for (final e in pending)
      if (e.kind == 'txDelete') e.path.split('/').last,
  };

  var income = base.summary.income;
  var expenses = base.summary.expenses;
  var balance = base.summary.balance;
  var spent = base.summary.budget.spent;

  final keptRecent = <RecentTransaction>[];
  for (final t in base.recentTransactions) {
    if (deletedIds.contains(t.id)) {
      if (t.amount > 0) {
        income -= t.amount;
        balance -= t.amount;
      } else {
        final mag = -t.amount;
        expenses -= mag;
        balance += mag;
        spent -= mag;
      }
      continue;
    }
    keptRecent.add(t);
  }

  final creates = <RecentTransaction>[];
  for (final e in pending) {
    if (e.kind != 'txCreate') continue;
    final r = _pendingRecentFrom(e, categories);
    if (r == null) continue;
    creates.add(r);
    final mag = -r.amount; // positive expense magnitude
    expenses += mag;
    balance -= mag;
    spent += mag;
  }

  final amount = base.summary.budget.amount;
  final pct = amount > 0 ? (spent / amount * 100).round() : 0;
  return DashboardState(
    summary: DashboardSummary(
      balance: balance,
      net: income - expenses,
      income: income,
      expenses: expenses,
      budget: BudgetInfo(amount: amount, spent: spent, pct: pct),
    ),
    recentTransactions: [...creates, ...keptRecent],
    month: base.month,
  );
}

/// Display state for the dashboard: the controller's data with the outbox
/// overlay applied. Actions still go through [dashboardControllerProvider].
final dashboardViewProvider = Provider<AsyncValue<DashboardState>>((ref) {
  final base = ref.watch(dashboardControllerProvider);
  final pending = ref.watch(pendingWritesProvider).value ?? const [];
  final categories =
      ref.watch(categoriesViewProvider).value ?? const <Category>[];
  return base.whenData((s) => overlayDashboard(s, pending, categories));
});
