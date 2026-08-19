import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/haptic_refresh.dart';
import '../../transactions/application/transactions_controller.dart';
import '../application/analytics_controller.dart';
import 'analytics_screen.dart';
import 'widgets/ai_insights_card.dart';
import 'widgets/donut_chart.dart';
import 'widgets/spending_bars.dart';

/// Expanded shell's left pane on Stats.
///
/// Two changes from the compact screen, both because the space is used
/// differently here:
///
/// * The donut gets the full width of its card and grows to 220 dp. Its legend
///   is gone — colour dot, label and percentage were a strict subset of what
///   the Spending Breakdown rows below already show, and side by side in a
///   narrow pane the duplication was impossible to miss.
/// * Those breakdown rows become the filter control for the companion feed, so
///   the one list of categories is also the one place you act on them.
class AnalyticsPane extends ConsumerWidget {
  const AnalyticsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final selectedCategoryId = ref
        .watch(transactionsControllerProvider)
        .asData
        ?.value
        .filters
        .categoryId;

    return async.when(
      loading: () => const AnalyticsSkeletonBody(),
      error: (e, _) => AnalyticsErrorBody(onRetry: controller.refresh),
      data: (state) {
        final data = state.data;
        if (data == null || data.isEmpty) {
          return AnalyticsEmptyBody(month: state.month);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: withRefreshHaptic(controller.refresh),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: state.loading ? 0.55 : 1.0,
            child: IgnorePointer(
              ignoring: state.loading,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  pageInsetOf(context),
                  8,
                  pageInsetOf(context),
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Center(child: DonutChart(data: data, size: 220)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Spending Breakdown',
                          style: AppTextStyles.titleS,
                        ),
                      ),
                      if (selectedCategoryId != null)
                        _ClearFilter(onTap: () => _select(ref, null)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    radius: 18,
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                    child: SpendingBars(
                      items: data.items,
                      selectedCategoryId: selectedCategoryId,
                      // Toggle off when tapping the row that is already active.
                      onSelect: (id) =>
                          _select(ref, id == selectedCategoryId ? null : id),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AiInsightsCard(month: data.month),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _select(WidgetRef ref, String? categoryId) {
    final filters = categoryId == null
        ? TransactionFilters.none
        : TransactionFilters(categoryId: categoryId);
    ref.read(transactionsControllerProvider.notifier).applyFilters(filters);
  }
}

class _ClearFilter extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearFilter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Show all',
        style: AppTextStyles.labelStrong.copyWith(
          color: AppColors.primary,
          fontSize: 13,
        ),
      ),
    );
  }
}
