import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/haptic_refresh.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../application/transactions_controller.dart';
import '../../data/transactions_repository.dart';
import '../../domain/date_grouping.dart';
import '../../domain/transaction.dart';
import '../transactions_screen.dart';
import 'day_group_card.dart';

/// The month's transactions with no chrome at all: no title, no month
/// navigator, no summary row.
///
/// This is the companion pane on Home and Stats. Those destinations already
/// state the month and the totals in their header, so repeating them here is
/// what made the unfolded layout look like two apps side by side. What is left
/// is the part that actually benefits from a second column — the list itself.
class ActivityFeedPane extends ConsumerStatefulWidget {
  /// Show the active category filter as a clearable chip. Used on Stats, where
  /// tapping a Spending Breakdown row filters this pane and the chip is the
  /// only visible trace of that.
  final bool showFilter;

  const ActivityFeedPane({super.key, this.showFilter = false});

  @override
  ConsumerState<ActivityFeedPane> createState() => _ActivityFeedPaneState();
}

class _ActivityFeedPaneState extends ConsumerState<ActivityFeedPane> {
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
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 400) {
      ref.read(transactionsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _delete(String id) async {
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(transactionsViewProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);

    return async.when(
      loading: () => const _FeedSkeleton(),
      error: (e, _) => InlineTransactionsError(onRetry: controller.refresh),
      data: (state) {
        if (state.contentLoading) return const _FeedSkeleton();
        if (state.contentError) {
          return InlineTransactionsError(
            onRetry: controller.reloadCurrentMonth,
          );
        }

        final groups = groupByDay(state.transactions);
        final inset = pageInsetOf(context);
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final filterLabel = widget.showFilter
            ? _filterLabel(state.filters)
            : null;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: withRefreshHaptic(controller.refresh),
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (filterLabel != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 16, inset, 0),
                  sliver: SliverToBoxAdapter(
                    child: _FilterChip(
                      label: filterLabel,
                      onClear: () {
                        HapticFeedback.selectionClick();
                        controller.clearFilters();
                      },
                    ),
                  ),
                ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: TransactionsEmptyState(
                    month: state.month,
                    filtersActive: state.filters.isActive,
                    onClearFilters: controller.clearFilters,
                  ),
                )
              else ...[
                for (final group in groups)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 14, inset, 0),
                    sliver: SliverToBoxAdapter(
                      child: DayGroupCard(group: group, onDelete: _delete),
                    ),
                  ),
                if (state.hasMore)
                  const SliverToBoxAdapter(child: PageSpinner()),
                SliverToBoxAdapter(child: SizedBox(height: 24 + bottomInset)),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Label for the active category filter, resolved from the loaded rows so we
  /// don't need the category list here. Null when nothing is filtered.
  String? _filterLabel(TransactionFilters filters) {
    final id = filters.categoryId;
    if (id == null) return null;
    final state = ref.read(transactionsViewProvider).value;
    for (final t in state?.transactions ?? const <Transaction>[]) {
      if (t.category.id == id) return t.category.label;
    }
    return 'Filtered';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _FilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Filtered by $label, tap to clear',
        child: Material(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final inset = pageInsetOf(context);
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(inset, 16, inset, 0),
        child: const Column(
          children: [
            SkeletonDayGroup(rows: 3),
            SizedBox(height: 14),
            SkeletonDayGroup(rows: 2),
            SizedBox(height: 14),
            SkeletonDayGroup(rows: 3),
          ],
        ),
      ),
    );
  }
}
