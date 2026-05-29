import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

@immutable
class TransactionsState {
  final String month; // YYYY-MM
  final List<Transaction> transactions;
  final String? nextCursor;
  final List<String> availableMonths;
  final double income;
  final double expenses;
  final bool loadingMore;

  const TransactionsState({
    required this.month,
    required this.transactions,
    required this.nextCursor,
    required this.availableMonths,
    required this.income,
    required this.expenses,
    this.loadingMore = false,
  });

  bool get hasMore => nextCursor != null;

  /// Whether the user is at the newest month they have transactions in.
  /// "Newest" is the first element of [availableMonths]; if there are no
  /// transactions yet, the current calendar month is treated as the only month.
  bool get isAtNewest =>
      availableMonths.isEmpty ? true : month == availableMonths.first;

  bool get isAtOldest =>
      availableMonths.isEmpty ? true : month == availableMonths.last;

  TransactionsState copyWith({
    String? month,
    List<Transaction>? transactions,
    String? nextCursor,
    List<String>? availableMonths,
    double? income,
    double? expenses,
    bool? loadingMore,
    bool clearNextCursor = false,
  }) =>
      TransactionsState(
        month: month ?? this.month,
        transactions: transactions ?? this.transactions,
        nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
        availableMonths: availableMonths ?? this.availableMonths,
        income: income ?? this.income,
        expenses: expenses ?? this.expenses,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

String _currentMonth() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

class TransactionsController extends AsyncNotifier<TransactionsState> {
  TransactionsRepository get _repo => ref.read(transactionsRepositoryProvider);
  DashboardRepository get _dash => ref.read(dashboardRepositoryProvider);

  @override
  Future<TransactionsState> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return TransactionsState(
        month: _currentMonth(),
        transactions: const [],
        nextCursor: null,
        availableMonths: const [],
        income: 0,
        expenses: 0,
      );
    }

    final months = await _repo.listMonths();
    final month = months.isNotEmpty ? months.first : _currentMonth();
    return _loadMonth(month: month, availableMonths: months);
  }

  Future<TransactionsState> _loadMonth({
    required String month,
    required List<String> availableMonths,
  }) async {
    final (page, summary) = await (
      _repo.list(month: month),
      _dash.getSummary(month: month),
    ).wait;
    return TransactionsState(
      month: month,
      transactions: page.transactions,
      nextCursor: page.nextCursor,
      availableMonths: availableMonths,
      income: summary.income,
      expenses: summary.expenses,
    );
  }

  Future<void> setMonth(String month) async {
    final current = state.value;
    if (current == null || current.month == month) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadMonth(month: month, availableMonths: current.availableMonths),
    );
  }

  Future<void> previousMonth() async {
    final cur = state.value;
    if (cur == null || cur.isAtOldest) return;
    final idx = cur.availableMonths.indexOf(cur.month);
    if (idx == -1 || idx + 1 >= cur.availableMonths.length) return;
    await setMonth(cur.availableMonths[idx + 1]);
  }

  Future<void> nextMonth() async {
    final cur = state.value;
    if (cur == null || cur.isAtNewest) return;
    final idx = cur.availableMonths.indexOf(cur.month);
    if (idx <= 0) return;
    await setMonth(cur.availableMonths[idx - 1]);
  }

  /// Appends the next page without disturbing the current AsyncData wrapper —
  /// the list keeps rendering while the spinner sits at the bottom.
  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;

    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final page = await _repo.list(month: cur.month, cursor: cur.nextCursor);
      state = AsyncData(
        cur.copyWith(
          transactions: [...cur.transactions, ...page.transactions],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(cur.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<void> refresh() async {
    final cur = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final months = await _repo.listMonths();
      final month = cur?.month ?? (months.isNotEmpty ? months.first : _currentMonth());
      return _loadMonth(month: month, availableMonths: months);
    });
  }
}

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, TransactionsState>(
  TransactionsController.new,
);
