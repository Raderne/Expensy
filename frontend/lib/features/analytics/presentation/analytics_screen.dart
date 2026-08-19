import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/haptic_refresh.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../application/analytics_controller.dart';
import '../domain/analytics_breakdown.dart';
import 'widgets/ai_insights_card.dart';
import 'widgets/analytics_header_bar.dart';
import 'widgets/donut_chart.dart';
import 'widgets/donut_legend.dart';
import 'widgets/spending_bars.dart';

/// Compact (phone / folded) Analytics: header, donut with its legend, then the
/// spending breakdown.
///
/// On an expanded window the shell uses [AnalyticsHeaderBar] as the destination
/// header and `AnalyticsPane` as the left pane instead — see `analytics_pane.dart`
/// for why the legend is dropped there.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);

    return async.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => Column(
        children: [
          const AnalyticsHeaderBar(),
          Expanded(child: AnalyticsErrorBody(onRetry: controller.refresh)),
        ],
      ),
      data: (state) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: withRefreshHaptic(controller.refresh),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: AnalyticsHeaderBar()),
            if (state.data == null || state.data!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AnalyticsEmptyBody(month: state.month),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pageInsetOf(context),
                  8,
                  pageInsetOf(context),
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverToBoxAdapter(
                  child: _Content(data: state.data!, loading: state.loading),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Content (donut + legend, then bars) ─────────────────────────────────────

class _Content extends StatelessWidget {
  final AnalyticsBreakdown data;
  final bool loading;

  const _Content({required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: loading ? 0.55 : 1.0,
      child: IgnorePointer(
        ignoring: loading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              radius: 22,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  DonutChart(data: data),
                  const SizedBox(width: 12),
                  Expanded(child: DonutLegend(items: data.items)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Spending Breakdown', style: AppTextStyles.titleS),
            const SizedBox(height: 14),
            GlassCard(
              radius: 18,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: SpendingBars(items: data.items),
            ),
            const SizedBox(height: 18),
            AiInsightsCard(month: data.month),
          ],
        ),
      ),
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AnalyticsHeaderBar(),
        Expanded(child: AnalyticsSkeletonBody()),
      ],
    );
  }
}

/// Skeleton for everything below the header. Shared with the expanded pane.
class AnalyticsSkeletonBody extends StatelessWidget {
  const AnalyticsSkeletonBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          pageInsetOf(context),
          8,
          pageInsetOf(context),
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000C22),
                    blurRadius: 18,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: ShimmerBox(height: 160, width: 160, radius: 80),
              ),
            ),
            const SizedBox(height: 18),
            const ShimmerBox(height: 16, width: 160, radius: 4),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000C22),
                    blurRadius: 14,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _SkeletonBarRow(),
                  SizedBox(height: 16),
                  _SkeletonBarRow(),
                  SizedBox(height: 16),
                  _SkeletonBarRow(),
                  SizedBox(height: 16),
                  _SkeletonBarRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBarRow extends StatelessWidget {
  const _SkeletonBarRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShimmerBox(height: 10, width: 10, radius: 5),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(height: 12, width: 80, radius: 4),
                  ShimmerBox(height: 12, width: 48, radius: 4),
                ],
              ),
              SizedBox(height: 6),
              ShimmerBox(height: 6, radius: 3),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalyticsErrorBody extends StatelessWidget {
  final Future<void> Function() onRetry;
  const AnalyticsErrorBody({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.inkLight),
            const SizedBox(height: 12),
            Text('Could not load analytics', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsEmptyBody extends StatelessWidget {
  final String month;
  const AnalyticsEmptyBody({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 13),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.mutedSmall.copyWith(
                      color: AppColors.inkMid,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('\$0', style: AppTextStyles.titleM),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No expenses in ${monthLabel(month)}',
              style: AppTextStyles.bodyStrong,
            ),
            const SizedBox(height: 4),
            Text(
              'Add an expense or pick a different month.',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
