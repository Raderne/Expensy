import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../application/analytics_insights_controller.dart';
import '../../data/analytics_repository.dart';
import '../../domain/spending_insights.dart';

/// The "AI Insights" panel on the Analytics screen. Idle until the user taps
/// Generate, then shows a loading skeleton, an error (branched on API code), or
/// the AI read-out. Keyed by [month] through `analyticsInsightsControllerProvider`.
class AiInsightsCard extends ConsumerWidget {
  final String month;
  const AiInsightsCard({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsInsightsControllerProvider(month));
    final controller = ref.read(
      analyticsInsightsControllerProvider(month).notifier,
    );

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            busy: state?.isLoading ?? false,
            showRefresh: state?.hasValue ?? false,
            onRefresh: () => controller.generate(refresh: true),
          ),
          const SizedBox(height: 16),
          if (state == null)
            _IdleState(onGenerate: controller.generate)
          else
            state.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                error: err,
                onRetry: () => controller.generate(refresh: true),
              ),
              data: (insights) => _InsightsContent(insights: insights),
            ),
        ],
      ),
    );
  }
}

// ─── Header (gradient sparkle badge + title) ─────────────────────────────────

class _Header extends StatelessWidget {
  final bool busy;
  final bool showRefresh;
  final VoidCallback onRefresh;

  const _Header({
    required this.busy,
    required this.showRefresh,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gradient badge — the one bold accent that marks this as AI.
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 19,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Insights', style: AppTextStyles.titleM),
              Text('Powered by your data', style: AppTextStyles.muted),
            ],
          ),
        ),
        if (showRefresh)
          IconButton(
            onPressed: busy ? null : onRefresh,
            tooltip: 'Regenerate',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: busy ? AppColors.inkFaint : AppColors.inkLight,
            ),
          ),
      ],
    );
  }
}

// ─── Idle (tap to generate) ──────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _IdleState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'See what stood out in your spending, budget, and recurring bills this month.',
          style: AppTextStyles.body.copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onGenerate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generate insights',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────────────

class _InsightsContent extends StatelessWidget {
  final SpendingInsights insights;
  const _InsightsContent({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.headline.isNotEmpty)
          Text(
            insights.headline,
            style: AppTextStyles.titleS.copyWith(fontSize: 16, height: 1.3),
          ),
        if (insights.summary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            insights.summary,
            style: AppTextStyles.body.copyWith(height: 1.4),
          ),
        ],
        if (insights.savingsRatePct != null) ...[
          const SizedBox(height: 12),
          _SavingsPill(pct: insights.savingsRatePct!),
        ],
        const SizedBox(height: 16),
        ...insights.insights.map((i) => _InsightRow(insight: i)),
        if (insights.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Suggestions', style: AppTextStyles.titleS),
          const SizedBox(height: 10),
          ...insights.suggestions.map(_suggestionRow),
        ],
        const SizedBox(height: 12),
        Text('AI-generated · for guidance only', style: AppTextStyles.mutedSmall),
      ],
    );
  }

  Widget _suggestionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(height: 1.35)),
          ),
        ],
      ),
    );
  }
}

/// Visual mapping for an insight's sentiment: accent color + icon.
({Color accent, IconData icon}) _sentimentStyle(InsightSentiment s) {
  switch (s) {
    case InsightSentiment.positive:
      return (accent: AppColors.successInk, icon: Icons.trending_up_rounded);
    case InsightSentiment.warning:
      return (accent: AppColors.accentInk, icon: Icons.warning_amber_rounded);
    case InsightSentiment.neutral:
      return (accent: AppColors.inkLight, icon: Icons.info_outline_rounded);
  }
}

class _InsightRow extends StatelessWidget {
  final Insight insight;
  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final style = _sentimentStyle(insight.sentiment);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sentiment rail.
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: style.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(style.icon, size: 16, color: style.accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: AppTextStyles.bodyStrong),
                  if (insight.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      insight.detail,
                      style: AppTextStyles.muted.copyWith(height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsPill extends StatelessWidget {
  final double pct;
  const _SavingsPill({required this.pct});

  @override
  Widget build(BuildContext context) {
    final positive = pct >= 0;
    final ink = positive ? AppColors.successInk : AppColors.dangerInk;
    final bg = positive ? AppColors.successLight : AppColors.dangerLight;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              positive
                  ? Icons.savings_outlined
                  : Icons.trending_down_rounded,
              size: 14,
              color: ink,
            ),
            const SizedBox(width: 5),
            Text(
              '${pct.round()}% saved',
              style: AppTextStyles.labelStrong.copyWith(
                color: ink,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading ─────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 16, width: 220, radius: 4),
          SizedBox(height: 10),
          ShimmerBox(height: 13),
          SizedBox(height: 6),
          ShimmerBox(height: 13, width: 240),
          SizedBox(height: 18),
          _SkeletonInsight(),
          SizedBox(height: 14),
          _SkeletonInsight(),
          SizedBox(height: 14),
          _SkeletonInsight(),
        ],
      ),
    );
  }
}

class _SkeletonInsight extends StatelessWidget {
  const _SkeletonInsight();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(height: 32, width: 3, radius: 2),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 13, width: 130, radius: 4),
              SizedBox(height: 6),
              ShimmerBox(height: 12, radius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final code = error is AnalyticsApiException
        ? (error as AnalyticsApiException).code
        : null;

    final (IconData icon, String title, String body, bool canRetry) =
        switch (code) {
          'INSUFFICIENT_DATA' => (
            Icons.receipt_long_rounded,
            'Not enough to analyse yet',
            'Add a few transactions this month and try again.',
            false,
          ),
          'AI_UNAVAILABLE' => (
            Icons.cloud_off_rounded,
            'Insights unavailable',
            'AI insights are temporarily unavailable. Please try again later.',
            true,
          ),
          _ => (
            Icons.error_outline_rounded,
            'Couldn’t generate insights',
            'Something went wrong. Please try again.',
            true,
          ),
        };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.inkLight),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: AppTextStyles.body),
          if (canRetry) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
