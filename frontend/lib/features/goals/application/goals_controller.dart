import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/goals_repository.dart';
import '../domain/goal.dart';

class GoalsController extends AsyncNotifier<List<Goal>> {
  GoalsRepository get _repo => ref.read(goalsRepositoryProvider);

  @override
  Future<List<Goal>> build() async {
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

final goalsControllerProvider =
    AsyncNotifierProvider<GoalsController, List<Goal>>(GoalsController.new);
