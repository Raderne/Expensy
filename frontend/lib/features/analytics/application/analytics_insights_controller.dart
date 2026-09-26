import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../domain/financial_insights.dart';

/// On-demand financial insights for one analytics month. Starts **idle**
/// (`state == null`); nothing is fetched until the user opens the report, so a
/// Gemini call fires only when asked. Keyed by month, so each month carries its
/// own state.
///
/// Riverpod 3 family notifiers receive their argument via the create function,
/// so the month is injected through the constructor.
class InsightsController
    extends Notifier<AsyncValue<FinancialInsightsReport>?> {
  InsightsController(this._month);

  final String _month;

  AnalyticsRepository get _repo => ref.read(analyticsRepositoryProvider);

  @override
  AsyncValue<FinancialInsightsReport>? build() => null;

  /// Fetches the report. [refresh] forces a server-side recompute. A report
  /// already on screen stays visible while the new one loads.
  Future<void> generate({bool refresh = false}) async {
    final previous = state;
    if (previous != null && previous.hasValue) {
      // The only way to keep the last report on an in-flight AsyncValue.
      // Riverpod 3.2 marks the method @internal; there is no public equivalent.
      state =
          // ignore: invalid_use_of_internal_member
          const AsyncLoading<FinancialInsightsReport>().copyWithPrevious(
            previous,
          );
    } else {
      state = const AsyncLoading();
    }
    final next = await AsyncValue.guard(
      () => _repo.getInsights(month: _month, refresh: refresh),
    );
    if (next.hasError && previous != null && previous.hasValue) {
      state = AsyncError<FinancialInsightsReport>(
        next.error!,
        next.stackTrace!,
        // ignore: invalid_use_of_internal_member
      ).copyWithPrevious(previous);
    } else {
      state = next;
    }
  }
}

final analyticsInsightsControllerProvider =
    NotifierProvider.family<
      InsightsController,
      AsyncValue<FinancialInsightsReport>?,
      String
    >(InsightsController.new, retry: (_, _) => null);
