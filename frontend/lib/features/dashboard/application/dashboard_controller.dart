import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
