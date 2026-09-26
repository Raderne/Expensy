import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../application/analytics_insights_controller.dart';
import '../../data/analytics_repository.dart';
import '../../domain/financial_insights.dart';

/// Compact entry on Stats. The full review opens on its own screen.
class AiInsightsCard extends ConsumerWidget {
  final String month;
  const AiInsightsCard({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsInsightsControllerProvider(month));
    final report = state?.asData?.value ?? state?.value;
    final route = '/analytics/insights/$month';

    final Widget body;
    if (report != null) {
      body = _Preview(
        report: report,
        refreshing: state?.isLoading ?? false,
        onOpen: () => context.push(route),
      );
    } else if (state is AsyncError<FinancialInsightsReport>) {
      body = _ErrorState(
        error: state.error,
        onRetry: () {
          ref
              .read(analyticsInsightsControllerProvider(month).notifier)
              .generate(refresh: true);
          context.push(route);
        },
      );
    } else if (state?.isLoading ?? false) {
      body = Text(
        'Reviewing trends, budget, goals, and recurring commitments…',
        style: AppTextStyles.body.copyWith(height: 1.4),
      );
    } else {
      body = _IdleState(onGenerate: () => context.push(route));
    }

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const _Header(), const SizedBox(height: 16), body],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
              Text('Budget, cash flow, and goals', style: AppTextStyles.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdleState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _IdleState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reviews this month plus the five before it, along with your budget, recurring bills, and goals.',
          style: AppTextStyles.body.copyWith(height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Totals, category names, and goal names are sent to Google Gemini. Notes, contacts, and individual transactions stay in Expensy.',
          style: AppTextStyles.muted.copyWith(height: 1.35),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          icon: Icons.auto_awesome_rounded,
          label: 'Generate insights',
          onPressed: onGenerate,
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final FinancialInsightsReport report;
  final bool refreshing;
  final VoidCallback onOpen;

  const _Preview({
    required this.report,
    required this.refreshing,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final freshness = refreshing
        ? 'Refreshing…'
        : insightsFreshnessLabel(report.generatedAt, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          report.headline,
          style: AppTextStyles.titleS.copyWith(fontSize: 16, height: 1.3),
        ),
        const SizedBox(height: 6),
        Text(
          'Based on ${report.dataCoverage.historyMonths} months of history · $freshness',
          style: AppTextStyles.muted.copyWith(height: 1.3),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          icon: Icons.menu_book_outlined,
          label: 'Open report',
          onPressed: onOpen,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.labelStrong.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final code = error is AnalyticsApiException
        ? (error as AnalyticsApiException).code
        : null;
    final (String title, String body, bool canRetry) = switch (code) {
      'INSUFFICIENT_DATA' => (
        'Not enough to analyse yet',
        'Add income or an expense this month and try again.',
        false,
      ),
      _ => (
        'Couldn’t generate insights',
        'Something went wrong. Please try again.',
        true,
      ),
    };
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.bodyStrong,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(body, textAlign: TextAlign.center, style: AppTextStyles.body),
        if (canRetry) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              'Try again',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
