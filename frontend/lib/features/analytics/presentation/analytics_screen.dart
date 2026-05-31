import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/haptic_refresh.dart';
import '../application/analytics_controller.dart';
import '../domain/analytics_breakdown.dart';
import 'widgets/donut_chart.dart';
import 'widgets/donut_legend.dart';
import 'widgets/month_picker_sheet.dart';
import 'widgets/spending_bars.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);

    return async.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(onRetry: controller.refresh),
      data: (state) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: withRefreshHaptic(controller.refresh),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                month: state.month,
                onPickMonth: () => _pickMonth(context, ref, state),
              ),
            ),
            if (state.data == null || state.data!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(month: state.month),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _Content(data: state.data!, loading: state.loading),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    AnalyticsState state,
  ) async {
    final picked = await showMonthPickerSheet(
      context,
      months: state.availableMonths,
      selected: state.month,
    );
    if (picked != null && picked != state.month) {
      await ref.read(analyticsControllerProvider.notifier).setMonth(picked);
    }
  }
}

// ─── Header (title + month chip) ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String month;
  final VoidCallback onPickMonth;

  const _Header({required this.month, required this.onPickMonth});

  @override
  Widget build(BuildContext context) {
    final label = _monthLabel(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Analytics', style: AppTextStyles.titleL),
          _MonthChip(label: label, onTap: onPickMonth),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MonthChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelStrong.copyWith(
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.inkMid,
                size: 18,
              ),
            ],
          ),
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
              child: SpendingBars(items: data.items),
            ),
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
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorScaffold({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.inkLight),
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

class _EmptyState extends StatelessWidget {
  final String month;
  const _EmptyState({required this.month});

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
              'No expenses in ${_monthLabel(month)}',
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

String _monthLabel(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat('MMMM yyyy').format(dt);
}
