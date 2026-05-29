import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../transactions/data/transactions_repository.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_breakdown.dart';

@immutable
class AnalyticsState {
  final String month; // YYYY-MM
  final AnalyticsBreakdown? data;
  final List<String> availableMonths;
  final bool loading;

  const AnalyticsState({
    required this.month,
    required this.data,
    required this.availableMonths,
    this.loading = false,
  });

  AnalyticsState copyWith({
    String? month,
    AnalyticsBreakdown? data,
    List<String>? availableMonths,
    bool? loading,
  }) =>
      AnalyticsState(
        month: month ?? this.month,
        data: data ?? this.data,
        availableMonths: availableMonths ?? this.availableMonths,
        loading: loading ?? this.loading,
      );
}

String _currentMonth() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

class AnalyticsController extends AsyncNotifier<AnalyticsState> {
  AnalyticsRepository get _repo => ref.read(analyticsRepositoryProvider);
  TransactionsRepository get _txRepo =>
      ref.read(transactionsRepositoryProvider);

  @override
  Future<AnalyticsState> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return AnalyticsState(
        month: _currentMonth(),
        data: null,
        availableMonths: const [],
      );
    }

    final months = await _txRepo.listMonths();
    final month = months.isNotEmpty ? months.first : _currentMonth();
    final data = await _repo.get(month: month);
    return AnalyticsState(month: month, data: data, availableMonths: months);
  }

  /// Switches the visible month. Keeps the previous data on screen while the
  /// new month loads so the chart doesn't blank out.
  Future<void> setMonth(String month) async {
    final cur = state.value;
    if (cur == null || cur.month == month) return;

    state = AsyncData(cur.copyWith(month: month, loading: true));
    try {
      final data = await _repo.get(month: month);
      state = AsyncData(cur.copyWith(month: month, data: data, loading: false));
    } catch (e, st) {
      state = AsyncData(cur.copyWith(loading: false));
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    final cur = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final months = await _txRepo.listMonths();
      final month =
          cur?.month ?? (months.isNotEmpty ? months.first : _currentMonth());
      final data = await _repo.get(month: month);
      return AnalyticsState(month: month, data: data, availableMonths: months);
    });
  }
}

final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, AnalyticsState>(
  AnalyticsController.new,
);
