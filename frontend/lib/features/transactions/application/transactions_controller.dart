import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/categories_repository.dart';
import '../../../core/models/category.dart';
import '../../../core/sync/outbox.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

/// One of `'income'` / `'expense'`, or `null` for both.
typedef TxTypeFilter = String?;

@immutable
class TransactionFilters {
  final String? categoryId;
  final TxTypeFilter type;

  const TransactionFilters({this.categoryId, this.type});

  static const none = TransactionFilters();

  bool get isActive => categoryId != null || type != null;

  TransactionFilters copyWith({
    String? categoryId,
    TxTypeFilter type,
    bool clearCategoryId = false,
    bool clearType = false,
  }) => TransactionFilters(
    categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    type: clearType ? null : (type ?? this.type),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilters &&
          other.categoryId == categoryId &&
          other.type == type;

  @override
  int get hashCode => Object.hash(categoryId, type);
}

@immutable
class TransactionsState {
  final String month; // YYYY-MM
  final List<Transaction> transactions;
  final String? nextCursor;
  final List<String> availableMonths;
  final double income;
  final double expenses;
  final double net;
  final bool loadingMore;
  final TransactionFilters filters;

  const TransactionsState({
    required this.month,
    required this.transactions,
    required this.nextCursor,
    required this.availableMonths,
    required this.income,
    required this.expenses,
    required this.net,
    this.loadingMore = false,
    this.filters = TransactionFilters.none,
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
    double? net,
    bool? loadingMore,
    TransactionFilters? filters,
    bool clearNextCursor = false,
  }) => TransactionsState(
    month: month ?? this.month,
    transactions: transactions ?? this.transactions,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    availableMonths: availableMonths ?? this.availableMonths,
    income: income ?? this.income,
    expenses: expenses ?? this.expenses,
    net: net ?? this.net,
    loadingMore: loadingMore ?? this.loadingMore,
    filters: filters ?? this.filters,
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
        net: 0,
      );
    }

    // SWR: hand back the most recent cached snapshot immediately, then
    // refresh in the background. Only fires when we have BOTH cached months
    // and a cached first-page list for the newest month — otherwise fall
    // through to a clean network load.
    final cached = await _loadFromCache();
    if (cached != null) {
      unawaited(_refreshSilently());
      return cached;
    }

    final months = await _repo.listMonths();
    final month = months.isNotEmpty ? months.first : _currentMonth();
    return _loadMonth(
      month: month,
      availableMonths: months,
      filters: TransactionFilters.none,
    );
  }

  Future<TransactionsState?> _loadFromCache() async {
    final months = await _repo.readCachedMonths();
    if (months == null) return null;
    final month = months.isNotEmpty ? months.first : _currentMonth();
    final page = await _repo.readCachedFirstPage(month: month);
    if (page == null) return null;
    final summary = await _dash.readCachedSummary(month: month);
    if (summary == null) return null;
    return TransactionsState(
      month: month,
      transactions: page.transactions,
      nextCursor: page.nextCursor,
      availableMonths: months,
      income: summary.income,
      expenses: summary.expenses,
      net: summary.net,
    );
  }

  Future<void> _refreshSilently() async {
    try {
      final months = await _repo.listMonths();
      final month =
          state.value?.month ??
          (months.isNotEmpty ? months.first : _currentMonth());
      final fresh = await _loadMonth(
        month: month,
        availableMonths: months,
        filters: state.value?.filters ?? TransactionFilters.none,
      );
      state = AsyncData(fresh);
    } catch (e) {
      if (kDebugMode) debugPrint('Transactions background refresh failed: $e');
    }
  }

  Future<TransactionsState> _loadMonth({
    required String month,
    required List<String> availableMonths,
    required TransactionFilters filters,
  }) async {
    // Summary stays unfiltered — income/expense cards reflect the whole month
    // so the totals don't lie when a category filter is on.
    final (page, summary) = await (
      _repo.list(
        month: month,
        categoryId: filters.categoryId,
        type: filters.type,
      ),
      _dash.getSummary(month: month),
    ).wait;
    return TransactionsState(
      month: month,
      transactions: page.transactions,
      nextCursor: page.nextCursor,
      availableMonths: availableMonths,
      income: summary.income,
      expenses: summary.expenses,
      net: summary.net,
      filters: filters,
    );
  }

  Future<void> setMonth(String month) async {
    final current = state.value;
    if (current == null || current.month == month) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadMonth(
        month: month,
        availableMonths: current.availableMonths,
        filters: current.filters,
      ),
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

  /// Replaces the active filter set and reloads the current month.
  /// No-ops if [filters] equals the current filters.
  Future<void> applyFilters(TransactionFilters filters) async {
    final cur = state.value;
    if (cur == null || cur.filters == filters) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadMonth(
        month: cur.month,
        availableMonths: cur.availableMonths,
        filters: filters,
      ),
    );
  }

  Future<void> clearFilters() => applyFilters(TransactionFilters.none);

  /// Appends the next page without disturbing the current AsyncData wrapper —
  /// the list keeps rendering while the spinner sits at the bottom.
  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;

    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final page = await _repo.list(
        month: cur.month,
        cursor: cur.nextCursor,
        categoryId: cur.filters.categoryId,
        type: cur.filters.type,
      );
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
      final month =
          cur?.month ?? (months.isNotEmpty ? months.first : _currentMonth());
      return _loadMonth(
        month: month,
        availableMonths: months,
        filters: cur?.filters ?? TransactionFilters.none,
      );
    });
  }

  /// Offline-first: just queue the delete. The row (and its contribution to the
  /// month totals) is hidden by [transactionsViewProvider]'s overlay while the
  /// entry sits in the outbox; the real DELETE replays via the SyncEngine.
  Future<void> deleteTransaction(String id) => _repo.delete(id);
}

/// Builds a pending [Transaction] from a queued `txCreate` entry, resolving its
/// category from [categories]. Returns null if the category can't be resolved.
Transaction? _pendingTxFrom(OutboxEntry e, List<Category> categories) {
  final body = e.body;
  if (body == null) return null;
  final categoryId = body['categoryId'] as String?;
  final amount = (body['amount'] as num?)?.toDouble();
  final occurredAtRaw = body['occurredAt'] as String?;
  if (categoryId == null || amount == null) return null;
  Category? category;
  for (final c in categories) {
    if (c.id == categoryId) {
      category = c;
      break;
    }
  }
  if (category == null) return null;
  final occurredAt = occurredAtRaw != null
      ? DateTime.parse(occurredAtRaw).toLocal()
      : DateTime.now();
  return Transaction(
    id: e.tempId ?? e.id,
    amount: -amount, // expenses are stored negative server-side
    note: body['note'] as String?,
    occurredAt: occurredAt,
    category: category,
    pending: true,
  );
}

String _monthOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Overlays the controller's fetched state with still-pending outbox writes:
/// queued deletes are hidden (and removed from totals) and queued expense
/// creates for the active month are prepended (and added to totals). Both
/// reconcile to canonical data once the SyncEngine drains.
TransactionsState overlayTransactions(
  TransactionsState base,
  List<OutboxEntry> pending,
  List<Category> categories,
) {
  if (pending.isEmpty) return base;

  final deletedIds = <String>{
    for (final e in pending)
      if (e.kind == 'txDelete') e.path.split('/').last,
  };

  var income = base.income;
  var expenses = base.expenses;
  final kept = <Transaction>[];
  for (final t in base.transactions) {
    if (deletedIds.contains(t.id)) {
      if (t.amount > 0) {
        income -= t.amount;
      } else {
        expenses += t.amount; // amount negative → lowers the expense magnitude
      }
      continue;
    }
    kept.add(t);
  }

  final creates = <Transaction>[];
  for (final e in pending) {
    if (e.kind != 'txCreate') continue;
    final tx = _pendingTxFrom(e, categories);
    if (tx == null) continue;
    if (_monthOf(tx.occurredAt) != base.month) continue;
    final f = base.filters;
    if (f.type == 'income') continue; // creates here are always expenses
    if (f.categoryId != null && f.categoryId != tx.category.id) continue;
    creates.add(tx);
    expenses += -tx.amount; // tx.amount negative → add its magnitude
  }

  return base.copyWith(
    transactions: [...creates, ...kept],
    income: income,
    expenses: expenses,
    net: income - expenses,
  );
}

/// Display state for the transactions screen: the controller's data with the
/// outbox overlay applied. Actions still go through [transactionsControllerProvider].
final transactionsViewProvider = Provider<AsyncValue<TransactionsState>>((ref) {
  final base = ref.watch(transactionsControllerProvider);
  final pending = ref.watch(pendingWritesProvider).value ?? const [];
  final categories =
      ref.watch(categoriesViewProvider).value ?? const <Category>[];
  return base.whenData((s) => overlayTransactions(s, pending, categories));
});

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );
