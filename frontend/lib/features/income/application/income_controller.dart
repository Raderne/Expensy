import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/income_repository.dart';
import '../domain/recurring_income.dart';

class IncomeController extends AsyncNotifier<List<RecurringIncome>> {
  IncomeRepository get _repo => ref.read(incomeRepositoryProvider);

  @override
  Future<List<RecurringIncome>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return const [];
    }
    return _repo.listRecurring();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listRecurring());
  }
}

final incomeControllerProvider =
    AsyncNotifierProvider<IncomeController, List<RecurringIncome>>(
  IncomeController.new,
);

extension RecurringIncomeListX on List<RecurringIncome> {
  double get activeMonthlyTotal =>
      where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.amount);

  int get activeCount => where((s) => s.isActive).length;
}
