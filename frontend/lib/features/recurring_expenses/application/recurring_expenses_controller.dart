import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/recurring_expenses_repository.dart';
import '../domain/recurring_expense.dart';

class RecurringExpensesController
    extends AsyncNotifier<List<RecurringExpense>> {
  RecurringExpensesRepository get _repo =>
      ref.read(recurringExpensesRepositoryProvider);

  @override
  Future<List<RecurringExpense>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return const [];
    }
    return _repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.list());
  }
}

final recurringExpensesControllerProvider =
    AsyncNotifierProvider<RecurringExpensesController, List<RecurringExpense>>(
      RecurringExpensesController.new,
    );

extension RecurringExpensesListX on List<RecurringExpense> {
  int get activeCount => where((s) => s.isActive).length;

  /// Normalized monthly outflow across all active rules, using the standard
  /// conversions: weekly = amount * 52/12, biweekly = amount * 26/12, monthly
  /// = amount, custom = amount * 30/intervalDays.
  double get activeMonthlyTotal {
    var total = 0.0;
    for (final s in where((s) => s.isActive)) {
      total += _monthlyAmount(s);
    }
    return total;
  }
}

double _monthlyAmount(RecurringExpense s) {
  switch (s.frequency) {
    case RecurrenceFrequency.weekly:
      return s.amount * 52 / 12;
    case RecurrenceFrequency.biweekly:
      return s.amount * 26 / 12;
    case RecurrenceFrequency.monthly:
      return s.amount;
    case RecurrenceFrequency.custom:
      final days = s.intervalDays ?? 30;
      return s.amount * 30 / days;
  }
}
