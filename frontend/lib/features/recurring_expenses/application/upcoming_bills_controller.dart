import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/recurring_expenses_repository.dart';
import '../domain/upcoming_bill.dart';

class UpcomingBillsController extends AsyncNotifier<List<UpcomingBill>> {
  @override
  Future<List<UpcomingBill>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return const [];
    }
    return ref.read(recurringExpensesRepositoryProvider).upcoming();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recurringExpensesRepositoryProvider).upcoming(),
    );
  }
}

final upcomingBillsControllerProvider =
    AsyncNotifierProvider<UpcomingBillsController, List<UpcomingBill>>(
  UpcomingBillsController.new,
);
