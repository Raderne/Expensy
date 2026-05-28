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
    // Skip network calls until we know the user is authenticated.
    final authAsync = ref.watch(authControllerProvider);
    if (!authAsync.hasValue || authAsync.value is! AuthAuthenticated) {
      return _emptyState;
    }
    return _load(_currentMonth());
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
