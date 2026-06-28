import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/goals_repository.dart';
import '../domain/goal_estimate.dart';

/// On-demand AI estimate for a single goal. Built lazily the first time a UI
/// reads `goalEstimateControllerProvider(goalId)` (i.e. when the estimate sheet
/// opens), so we never fire a Gemini call unless the user asks for it.
///
/// Riverpod 3 family notifiers receive their argument via the create function,
/// so the goal id is injected through the constructor.
class GoalEstimateController extends AsyncNotifier<GoalEstimate> {
  GoalEstimateController(this._goalId);

  final String _goalId;

  GoalsRepository get _repo => ref.read(goalsRepositoryProvider);

  @override
  Future<GoalEstimate> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      throw StateError('Not authenticated');
    }
    return _repo.getEstimate(_goalId);
  }

  /// Forces a fresh server-side recompute (bypasses the backend cache).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getEstimate(_goalId, refresh: true),
    );
  }
}

final goalEstimateControllerProvider =
    AsyncNotifierProvider.family<GoalEstimateController, GoalEstimate, String>(
      GoalEstimateController.new,
      // Errors are terminal: an INSUFFICIENT_DATA / AI_UNAVAILABLE result must
      // not auto-retry (it would re-hit Gemini). The UI offers a manual retry.
      retry: (_, _) => null,
    );
