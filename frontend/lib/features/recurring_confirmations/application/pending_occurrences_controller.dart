import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/recurring_confirmations_repository.dart';
import '../domain/pending_occurrence.dart';

/// Recurring occurrences that are due and awaiting a confirm/postpone decision.
/// Rebuilds on login/logout; the dashboard watches this to drive the prompt.
class PendingOccurrencesController
    extends AsyncNotifier<List<PendingOccurrence>> {
  @override
  Future<List<PendingOccurrence>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return const [];
    }
    return ref.read(recurringConfirmationsRepositoryProvider).listPending();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recurringConfirmationsRepositoryProvider).listPending(),
    );
  }
}

final pendingOccurrencesControllerProvider =
    AsyncNotifierProvider<PendingOccurrencesController, List<PendingOccurrence>>(
      PendingOccurrencesController.new,
    );
