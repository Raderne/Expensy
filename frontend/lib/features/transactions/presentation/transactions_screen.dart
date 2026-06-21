import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/haptic_refresh.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../application/transactions_controller.dart';
import '../data/transactions_repository.dart';
import '../domain/date_grouping.dart';
import 'widgets/filters_sheet.dart';
import 'widgets/month_nav.dart';
import 'widgets/summary_row.dart';
import 'widgets/swipeable_transaction_row.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger the next page when the user is within ~400px of the bottom.
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 400) {
      ref.read(transactionsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(transactionsViewProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);

    return async.when(
      loading: () => const _Loading(),
      error: (e, _) => _ErrorView(onRetry: controller.refresh),
      data: (state) {
        final groups = groupByDay(state.transactions);
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: withRefreshHaptic(controller.refresh),
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _TransactionsHero(
                  month: state.month,
                  canGoPrev: !state.isAtOldest,
                  canGoNext: !state.isAtNewest,
                  onPrev: controller.previousMonth,
                  onNext: controller.nextMonth,
                  filtersActive: state.filters.isActive,
                  onOpenFilters: () => _openFilters(context, state.filters),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                sliver: SliverToBoxAdapter(
                  child: SummaryRow(
                    income: state.income,
                    expenses: state.expenses,
                    net: state.net,
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    month: state.month,
                    filtersActive: state.filters.isActive,
                    onClearFilters: controller.clearFilters,
                  ),
                )
              else ...[
                for (final group in groups)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    sliver: SliverToBoxAdapter(
                      child: _DayGroup(
                        group: group,
                        onDelete: _deleteTransaction,
                      ),
                    ),
                  ),
                if (state.hasMore)
                  const SliverToBoxAdapter(child: _PageSpinner()),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 24 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openFilters(BuildContext context, TransactionFilters current) {
    showTransactionsFiltersSheet(
      context,
      initial: current,
      onApply: (filters) => ref
          .read(transactionsControllerProvider.notifier)
          .applyFilters(filters),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(transactionsControllerProvider.notifier)
          .deleteTransaction(id);
    } on TransactionsApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }
}

// ─── Hero header ─────────────────────────────────────────────────────────────

class _TransactionsHero extends StatelessWidget {
  final String month;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool filtersActive;
  final VoidCallback onOpenFilters;

  const _TransactionsHero({
    required this.month,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.filtersActive,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: HeroGradient.decoration,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 18),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Transactions',
                  style: AppTextStyles.titleL.copyWith(color: Colors.white),
                ),
                const Spacer(),
                _FilterButton(active: filtersActive, onTap: onOpenFilters),
              ],
            ),
            const SizedBox(height: 16),
            MonthNav(
              month: month,
              canGoPrev: canGoPrev,
              canGoNext: canGoNext,
              onPrev: onPrev,
              onNext: onNext,
              onHero: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Filters, active' : 'Filters',
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(16, 13),
                    painter: _FilterIconPainter(),
                  ),
                ),
                if (active)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
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

class _FilterIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    void bar(double x, double y, double w) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, 1.8),
          const Radius.circular(0.9),
        ),
        paint,
      );
    }

    bar(0, 0, 16);
    bar(3, 5.5, 10);
    bar(6, 11, 4);
  }

  @override
  bool shouldRepaint(covariant _FilterIconPainter oldDelegate) => false;
}

// ─── Empty / loading / error states ──────────────────────────────────────────

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Shimmer(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topInset + 8)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(height: 22, width: 148, radius: 6),
                  ShimmerBox(height: 36, width: 36, radius: 11),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
            sliver: SliverToBoxAdapter(
              child: ShimmerBox(height: 44, radius: 14),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: ShimmerBox(height: 80, radius: 16)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerBox(height: 80, radius: 16)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerBox(height: 80, radius: 16)),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(child: _SkeletonDayGroup(rows: 3)),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(child: _SkeletonDayGroup(rows: 2)),
          ),
        ],
      ),
    );
  }
}

class _SkeletonDayGroup extends StatelessWidget {
  const _SkeletonDayGroup({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: ShimmerBox(height: 13, width: 90, radius: 4),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000C22),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < rows; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 68,
                      color: AppColors.border,
                    ),
                  const _SkeletonTransactionRow(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonTransactionRow extends StatelessWidget {
  const _SkeletonTransactionRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ShimmerBox(height: 40, width: 40, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 13, width: 120, radius: 4),
                SizedBox(height: 6),
                ShimmerBox(height: 11, width: 70, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerBox(height: 13, width: 56, radius: 4),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

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
            Text(
              'Could not load transactions',
              style: AppTextStyles.bodyStrong,
            ),
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
  final bool filtersActive;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.month,
    required this.filtersActive,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final parts = month.split('-');
    final monthLabel = parts.length == 2
        ? _monthName(int.tryParse(parts[1]) ?? 0)
        : 'this month';
    final title = filtersActive
        ? 'No matches in $monthLabel'
        : 'No transactions in $monthLabel';
    final subtitle = filtersActive
        ? 'Try a different category or type.'
        : 'Add an expense or pick a different month.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.body),
            if (filtersActive) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClearFilters,
                child: Text(
                  'Clear filters',
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

  static const _names = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _monthName(int m) =>
      (m >= 1 && m <= 12) ? _names[m] : 'this month';
}

class _PageSpinner extends StatelessWidget {
  const _PageSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Day group card ───────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  final TransactionGroup group;
  final Future<void> Function(String id) onDelete;

  const _DayGroup({required this.group, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(group.label, style: AppTextStyles.groupLabel),
        ),
        GlassCard(
          radius: 16,
          strong: true,
          blur: 14,
          child: Column(
            children: [
              for (int i = 0; i < group.transactions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 68,
                    color: AppColors.glassBorder,
                  ),
                SwipeableTransactionRow(
                  transaction: group.transactions[i],
                  onDelete: () => onDelete(group.transactions[i].id),
                  onTap: group.transactions[i].isShared
                      ? () => context.push('/shared')
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
