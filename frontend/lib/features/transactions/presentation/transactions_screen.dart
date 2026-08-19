import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/haptic_refresh.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../application/month_nav_direction.dart';
import '../application/transactions_controller.dart';
import '../data/transactions_repository.dart';
import '../domain/date_grouping.dart';
import 'widgets/day_group_card.dart';
import 'widgets/summary_row.dart';
import 'widgets/transactions_header_bar.dart';

/// Compact (phone / folded) Transactions: the hero header above the month body.
///
/// On an expanded window the shell hoists [TransactionsHeaderBar] into the
/// destination header and renders [TransactionsBody] alone in the left pane, so
/// the two pieces are deliberately independent of each other.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        TransactionsHeaderBar(),
        Expanded(child: TransactionsBody()),
      ],
    );
  }
}

/// Everything below the header: the month summary and the day-grouped list,
/// with a slide+fade transition and swipe-to-change-month.
class TransactionsBody extends ConsumerStatefulWidget {
  const TransactionsBody({super.key});

  @override
  ConsumerState<TransactionsBody> createState() => _TransactionsBodyState();
}

class _TransactionsBodyState extends ConsumerState<TransactionsBody> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(transactionsViewProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);
    final navDir = ref.watch(monthNavDirectionProvider);

    return async.when(
      loading: () => const _BodySkeleton(),
      error: (e, _) => _ErrorView(onRetry: controller.refresh),
      data: (state) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) => _onSwipe(d, state, controller),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: Offset(0.08 * navDir, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: [...previousChildren, ?currentChild],
          ),
          child: KeyedSubtree(
            key: ValueKey(
              '${state.month}:${state.contentLoading}:${state.contentError}',
            ),
            child: state.contentLoading
                ? const _BodySkeleton()
                : _MonthBody(
                    state: state,
                    onRefresh: controller.refresh,
                    onRetry: controller.reloadCurrentMonth,
                    onLoadMore: controller.loadMore,
                    onDelete: _deleteTransaction,
                    onClearFilters: controller.clearFilters,
                  ),
          ),
        ),
      ),
    );
  }

  void _onSwipe(
    DragEndDetails details,
    TransactionsState state,
    TransactionsController controller,
  ) {
    final vx = details.primaryVelocity ?? 0;
    if (vx.abs() < 220) return;
    final dir = ref.read(monthNavDirectionProvider.notifier);
    if (vx > 0) {
      // Swipe right → previous (older) month.
      if (state.isAtOldest) return;
      dir.older();
      controller.previousMonth();
    } else {
      // Swipe left → next (newer) month.
      if (state.isAtNewest) return;
      dir.newer();
      controller.nextMonth();
    }
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

// ─── Month body (scrollable content below the header) ────────────────────────

class _MonthBody extends StatefulWidget {
  final TransactionsState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(String id) onDelete;
  final VoidCallback onClearFilters;

  const _MonthBody({
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onLoadMore,
    required this.onDelete,
    required this.onClearFilters,
  });

  @override
  State<_MonthBody> createState() => _MonthBodyState();
}

class _MonthBodyState extends State<_MonthBody> {
  // Each month body owns its scroll controller. That keeps position per-month
  // and avoids two bodies briefly sharing one controller during the switch
  // animation (which would throw).
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
    if (remaining < 400) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final groups = groupByDay(state.transactions);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: withRefreshHaptic(widget.onRefresh),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state.contentError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: InlineTransactionsError(onRetry: widget.onRetry),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                pageInsetOf(context),
                16,
                pageInsetOf(context),
                4,
              ),
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
                child: TransactionsEmptyState(
                  month: state.month,
                  filtersActive: state.filters.isActive,
                  onClearFilters: widget.onClearFilters,
                ),
              )
            else ...[
              for (final group in groups)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pageInsetOf(context),
                    12,
                    pageInsetOf(context),
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: DayGroupCard(
                      group: group,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ),
              if (state.hasMore) const SliverToBoxAdapter(child: PageSpinner()),
              SliverToBoxAdapter(child: SizedBox(height: 24 + bottomInset)),
            ],
          ],
        ],
      ),
    );
  }
}

/// Skeleton for the body while a month/filter reload is in flight. Excludes the
/// header — that stays put during the swap.
class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pageInsetOf(context),
                16,
                pageInsetOf(context),
                14,
              ),
              child: const Row(
                children: [
                  Expanded(child: ShimmerBox(height: 80, radius: 16)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerBox(height: 80, radius: 16)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerBox(height: 80, radius: 16)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pageInsetOf(context)),
              child: const SkeletonDayGroup(rows: 3),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                pageInsetOf(context),
                12,
                pageInsetOf(context),
                0,
              ),
              child: const SkeletonDayGroup(rows: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineTransactionsError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const InlineTransactionsError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Retry(title: 'Could not load this month', onRetry: () => onRetry());
  }
}

// ─── Empty / loading / error states ──────────────────────────────────────────

class SkeletonDayGroup extends StatelessWidget {
  const SkeletonDayGroup({super.key, required this.rows});

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
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Retry(
      title: 'Could not load transactions',
      onRetry: () => onRetry(),
    );
  }
}

class _Retry extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _Retry({required this.title, required this.onRetry});

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
            Text(title, style: AppTextStyles.bodyStrong),
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

class TransactionsEmptyState extends StatelessWidget {
  final String month;
  final bool filtersActive;
  final VoidCallback onClearFilters;

  const TransactionsEmptyState({
    super.key,
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

class PageSpinner extends StatelessWidget {
  const PageSpinner({super.key});

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
