import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/rollovers_repository.dart';
import '../domain/budget_rollover.dart';

/// Leftover budget from closed months that can still be moved into goals.
/// Errors resolve to an empty list at the call site (the prompt just hides).
class RolloversController extends AsyncNotifier<List<BudgetRollover>> {
  RolloversRepository get _repo => ref.read(rolloversRepositoryProvider);

  @override
  Future<List<BudgetRollover>> build() async {
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

final rolloversControllerProvider =
    AsyncNotifierProvider<RolloversController, List<BudgetRollover>>(
      RolloversController.new,
    );
