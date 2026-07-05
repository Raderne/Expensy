import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../domain/spending_insights.dart';

/// On-demand AI insights for one analytics month. Starts **idle**
/// (`state == null`); nothing is fetched until the user taps "Generate
/// insights", so a Gemini call fires only when asked. Keyed by month, so each
/// month carries its own state (switching months resets to idle).
///
/// Riverpod 3 family notifiers receive their argument via the create function,
/// so the month is injected through the constructor.
class InsightsController extends Notifier<AsyncValue<SpendingInsights>?> {
  InsightsController(this._month);

  final String _month;

  AnalyticsRepository get _repo => ref.read(analyticsRepositoryProvider);

  @override
  AsyncValue<SpendingInsights>? build() => null;

  /// Fetches insights for this month. [refresh] forces a server-side recompute.
  Future<void> generate({bool refresh = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getInsights(month: _month, refresh: refresh),
    );
  }
}

final analyticsInsightsControllerProvider =
    NotifierProvider.family<
      InsightsController,
      AsyncValue<SpendingInsights>?,
      String
    >(InsightsController.new);
