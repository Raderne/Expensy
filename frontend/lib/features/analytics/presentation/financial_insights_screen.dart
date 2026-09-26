import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../transactions/application/transactions_controller.dart';
import '../application/analytics_insights_controller.dart';
import '../data/analytics_repository.dart';
import '../domain/financial_insights.dart';
import 'widgets/insights_report.dart';

/// Full-screen financial review opened from Stats. Generates on first visit
/// and keeps the last report visible while a refresh is in flight.
class FinancialInsightsScreen extends ConsumerStatefulWidget {
  final String month;
  const FinancialInsightsScreen({super.key, required this.month});

  @override
  ConsumerState<FinancialInsightsScreen> createState() =>
      _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState
    extends ConsumerState<FinancialInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !insightMonthPattern.hasMatch(widget.month)) return;
      final state = ref.read(analyticsInsightsControllerProvider(widget.month));
      if (state == null) {
        ref
            .read(analyticsInsightsControllerProvider(widget.month).notifier)
            .generate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final valid = insightMonthPattern.hasMatch(widget.month);
    final state = valid
        ? ref.watch(analyticsInsightsControllerProvider(widget.month))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              busy: state?.isLoading ?? false,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/analytics');
                }
              },
              onRefresh: valid && !(state?.isLoading ?? false)
                  ? () => ref
                        .read(
                          analyticsInsightsControllerProvider(
                            widget.month,
                          ).notifier,
                        )
                        .generate(refresh: true)
                  : null,
            ),
            Expanded(child: _body(valid, state)),
          ],
        ),
      ),
    );
  }

  Widget _body(bool valid, AsyncValue<FinancialInsightsReport>? state) {
    if (!valid) {
      return const _MessageState(
        icon: Icons.error_outline_rounded,
        title: 'That month is not valid',
        body: 'Go back and pick a month from Stats.',
      );
    }
    final report = state?.asData?.value ?? state?.value;
    if (report != null) {
      return _ReportScroll(
        report: report,
        refreshing: state?.isLoading ?? false,
        refreshFailed: (state?.hasError ?? false),
        onOpen: (action) => _open(context, action),
      );
    }
    if (state is AsyncError<FinancialInsightsReport>) {
      return _ErrorState(
        error: state.error,
        onRetry: () => ref
            .read(analyticsInsightsControllerProvider(widget.month).notifier)
            .generate(refresh: true),
      );
    }
    return const _LoadingState();
  }

  void _open(BuildContext context, InsightAction action) {
    if (action.target == InsightActionTarget.transactions) {
      ref
          .read(transactionsControllerProvider.notifier)
          .applyFilters(
            action.categoryId == null
                ? TransactionFilters.none
                : TransactionFilters(categoryId: action.categoryId),
          );
    }
    context.go(insightPath(action.target));
  }
}

class _Toolbar extends StatelessWidget {
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;

  const _Toolbar({
    required this.busy,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
    final refresh = TextButton(
      onPressed: onRefresh,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(
        busy ? 'Refreshing…' : 'Refresh analysis',
        style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
      ),
    );
    final title = Text('Financial insights', style: AppTextStyles.titleM);
    return Padding(
      padding: EdgeInsets.fromLTRB(pageInsetOf(context) - 4, 8, 8, 4),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HeaderBackButton.onSurface(onTap: onBack),
                    const SizedBox(width: 8),
                    Expanded(child: title),
                  ],
                ),
                refresh,
              ],
            )
          : Row(
              children: [
                HeaderBackButton.onSurface(onTap: onBack),
                const SizedBox(width: 8),
                Expanded(child: title),
                refresh,
              ],
            ),
    );
  }
}

class _ReportScroll extends StatelessWidget {
  final FinancialInsightsReport report;
  final bool refreshing;
  final bool refreshFailed;
  final ValueChanged<InsightAction> onOpen;

  const _ReportScroll({
    required this.report,
    required this.refreshing,
    required this.refreshFailed,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= Breakpoints.expanded;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            pageInsetOf(context),
            8,
            pageInsetOf(context),
            24,
          ),
          children: [
            if (!report.commentaryAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Commentary is unavailable right now. These figures are calculated from your data.',
                  style: AppTextStyles.body.copyWith(height: 1.35),
                ),
              ),
            if (refreshFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'The latest refresh failed. This is the previous report.',
                  style: AppTextStyles.body,
                ),
              ),
            if (refreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                ),
              ),
            InsightsReportBody(report: report, wide: wide, onOpen: onOpen),
          ],
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        pageInsetOf(context),
        8,
        pageInsetOf(context),
        24,
      ),
      children: [
        Text(
          'Reviewing trends, budget, goals, and recurring commitments…',
          style: AppTextStyles.body.copyWith(height: 1.4),
        ),
        const SizedBox(height: 18),
        const Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 88, radius: 16),
              SizedBox(height: 12),
              ShimmerBox(height: 72, radius: 16),
              SizedBox(height: 12),
              ShimmerBox(height: 140, radius: 16),
            ],
          ),
        ),
      ],
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
    final (
      IconData icon,
      String title,
      String body,
      bool canRetry,
    ) = switch (code) {
      'INSUFFICIENT_DATA' => (
        Icons.receipt_long_rounded,
        'Not enough to analyse yet',
        'Add income or an expense this month and try again.',
        false,
      ),
      _ => (
        Icons.error_outline_rounded,
        'Couldn’t generate insights',
        'Something went wrong. Please try again.',
        true,
      ),
    };
    return _MessageState(
      icon: icon,
      title: title,
      body: body,
      onRetry: canRetry ? onRetry : null,
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AppColors.inkLight),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyStrong,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center, style: AppTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
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
        ),
      ),
    );
  }
}
