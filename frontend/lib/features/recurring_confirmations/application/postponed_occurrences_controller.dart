import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/recurring_confirmations_repository.dart';
import '../domain/pending_occurrence.dart';

/// Recurring occurrences the user pushed to a later day. Drives the dashboard
/// "Postponed" card and the management screen. Rebuilds on login/logout.
class PostponedOccurrencesController
    extends AsyncNotifier<List<PendingOccurrence>> {
  @override
  Future<List<PendingOccurrence>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return const [];
    }
    return ref.read(recurringConfirmationsRepositoryProvider).listPostponed();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recurringConfirmationsRepositoryProvider).listPostponed(),
    );
  }
}

final postponedOccurrencesControllerProvider =
    AsyncNotifierProvider<
      PostponedOccurrencesController,
      List<PendingOccurrence>
    >(PostponedOccurrencesController.new);
