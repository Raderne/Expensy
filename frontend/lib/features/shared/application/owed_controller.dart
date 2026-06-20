import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/shared_repository.dart';
import '../domain/owed_overview.dart';

/// Loads the "who owes me" overview, gated on auth. Auto-disposed so the screen
/// refetches fresh each visit — owed records created elsewhere (e.g. confirming
/// a shared recurring charge) always show up without a manual refresh.
class OwedController extends AsyncNotifier<OwedOverview> {
  @override
  Future<OwedOverview> build() async {
    final auth = ref.watch(authControllerProvider);
    if (!auth.hasValue || auth.value is! AuthAuthenticated) {
      return OwedOverview.empty;
    }
    return ref.read(sharedRepositoryProvider).owed();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(sharedRepositoryProvider).owed());
  }
}

final owedControllerProvider =
    AsyncNotifierProvider.autoDispose<OwedController, OwedOverview>(
      OwedController.new,
    );
