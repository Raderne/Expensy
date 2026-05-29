import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phase 06 placeholder.
///
/// Why: the Add Expense flow invalidates dashboard + transactions + analytics
/// so a returning screen shows the new row without a manual refresh. The real
/// AnalyticsController (donut + breakdown) lands in Phase 06; until then this
/// stub gives [ref.invalidate] a stable target so the wiring doesn't need to
/// change when Phase 06 swaps in the actual implementation.
final analyticsControllerProvider = FutureProvider.autoDispose<void>((ref) async {});
