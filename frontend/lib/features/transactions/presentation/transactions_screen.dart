import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/tx_row.dart';
import '../application/transactions_controller.dart';
import '../domain/date_grouping.dart';
import 'widgets/filters_sheet.dart';
import 'widgets/month_nav.dart';
import 'widgets/summary_row.dart';

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
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 400) {
      ref.read(transactionsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(transactionsControllerProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);

    return async.when(
      loading: () => const _Loading(),
      error: (e, _) => _ErrorView(onRetry: controller.refresh),
      data: (state) {
        final groups = groupByDay(state.transactions);
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  filtersActive: state.filters.isActive,
                  onOpenFilters: () => _openFilters(context, state.filters),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                sliver: SliverToBoxAdapter(
                  child: MonthNav(
                    month: state.month,
                    canGoPrev: !state.isAtOldest,
                    canGoNext: !state.isAtNewest,
                    onPrev: controller.previousMonth,
                    onNext: controller.nextMonth,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                sliver: SliverToBoxAdapter(
                  child: SummaryRow(
                    income: state.income,
                    expenses: state.expenses,
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
                for (final group in groups) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                    sliver: SliverToBoxAdapter(
                      child: Text(group.label, style: AppTextStyles.groupLabel),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.builder(
                      itemCount: group.transactions.length,
                      itemBuilder: (_, i) {
                        final tx = group.transactions[i];
                        return TxRow(
                          label: tx.category.label,
                          note: tx.note,
                          amount: tx.amount,
                          categoryAbbr: tx.category.abbr,
                          categoryColor: tx.category.colorValue,
                          categoryBg: tx.category.bgTintValue,
                        );
                      },
                    ),
                  ),
                ],
                if (state.hasMore)
                  const SliverToBoxAdapter(child: _PageSpinner()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
      onApply: (filters) =>
          ref.read(transactionsControllerProvider.notifier).applyFilters(filters),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool filtersActive;
  final VoidCallback onOpenFilters;

  const _Header({
    required this.filtersActive,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Transactions', style: AppTextStyles.titleL),
          _FilterButton(active: filtersActive, onTap: onOpenFilters),
        ],
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x17000C22),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
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
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
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
    final paint = Paint()..color = AppColors.inkMid;
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
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
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
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.inkLight),
            const SizedBox(height: 12),
            Text('Could not load transactions', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4),
            Text('Check your connection and try again.', style: AppTextStyles.body),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
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
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
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
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }
}
