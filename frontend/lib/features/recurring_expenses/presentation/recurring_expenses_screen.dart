import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/collapsing_hero.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../analytics/application/analytics_controller.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../recurring_confirmations/application/pending_occurrences_controller.dart';
import '../../recurring_confirmations/presentation/confirmation_queue.dart';
import '../../transactions/application/transactions_controller.dart';
import '../application/recurring_expenses_controller.dart';
import '../application/upcoming_bills_controller.dart';
import '../data/recurring_expenses_repository.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_expense.dart';
import 'widgets/edit_recurring_expense_sheet.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recurringExpensesControllerProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverCollapsingHero(
            minHeight: topInset + 56,
            // Sized to the expanded content (header + total card) plus a little
            // headroom so the title clears the status bar; minHeight is the
            // collapsed bar and isn't affected.
            maxHeight: topInset + 178,
            expanded: Padding(
              padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _heroHeader(context, 'Recurring expenses'),
                  const SizedBox(height: 14),
                  _TotalCard(asyncValue: async),
                ],
              ),
            ),
            collapsed: Padding(
              padding: EdgeInsets.only(top: topInset, left: 18, right: 18),
              child: SizedBox(
                height: 56,
                child: _heroHeader(context, 'Recurring expenses'),
              ),
            ),
          ),
          async.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, _) => SliverFillRemaining(
              child: Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(recurringExpensesControllerProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
            data: (rules) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              sliver: SliverList.list(
                children: [
                  if (rules.isEmpty)
                    const _EmptyState()
                  else
                    ...rules.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RuleCard(
                          rule: r,
                          onEdit: () => _openEdit(context, r),
                          onToggle: () => _toggleActive(ref, r),
                          onDelete: () => _confirmDelete(context, ref, r),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _AddButton(onTap: () => _openAdd(context, ref)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Back button + centered title, shared by the expanded hero and the
  /// collapsed bar so the title holds its position through the shrink.
  Widget _heroHeader(BuildContext context, String title) => Row(
    children: [
      HeaderBackButton.onHero(onTap: () => context.pop()),
      const Spacer(),
      Text(title, style: AppTextStyles.titleM.copyWith(color: Colors.white)),
      const Spacer(),
      const SizedBox(width: 44),
    ],
  );

  Future<void> _openAdd(BuildContext context, WidgetRef ref) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => const EditRecurringExpenseSheet(),
    );
    if (ok != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription added'),
        backgroundColor: AppColors.success,
      ),
    );

    // If the new rule's first charge is due today, prompt to confirm/postpone
    // right away (reuses the same dashboard modal).
    ref.invalidate(pendingOccurrencesControllerProvider);
    await runConfirmationQueue(context);
  }

  Future<void> _openEdit(BuildContext context, RecurringExpense rule) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => EditRecurringExpenseSheet(existing: rule),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _toggleActive(WidgetRef ref, RecurringExpense rule) async {
    HapticFeedback.selectionClick();
    try {
      await ref
          .read(recurringExpensesRepositoryProvider)
          .update(id: rule.id, isActive: !rule.isActive);
      _invalidate(ref);
    } on RecurringExpensesApiException catch (_) {
      // swallow; surfaced as no-change on UI
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense rule,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove subscription?', style: AppTextStyles.titleM),
        content: Text(
          'Future charges from "${rule.label}" will stop. Past transactions stay in your history.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.inkMid,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(recurringExpensesRepositoryProvider).remove(rule.id);
      _invalidate(ref);
      messenger.showSnackBar(
        const SnackBar(content: Text('Subscription removed')),
      );
    } on RecurringExpensesApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(recurringExpensesControllerProvider);
    ref.invalidate(upcomingBillsControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(analyticsControllerProvider);
  }
}

class _TotalCard extends StatelessWidget {
  final AsyncValue<List<RecurringExpense>> asyncValue;

  const _TotalCard({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final (activeCount, total) = switch (asyncValue) {
      AsyncData(:final value) => (value.activeCount, value.activeMonthlyTotal),
      _ => (0, 0.0),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active monthly outflow',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total > 0 ? '${money.format(total)} / mo' : '—',
                  style: AppTextStyles.titleM.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$activeCount active',
              style: AppTextStyles.labelStrong.copyWith(
                color: Colors.white,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RecurringExpense rule;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final categoryColor =
        AppColors.categories[rule.categoryKey]?.color ?? AppColors.primary;
    final categoryBg =
        AppColors.categories[rule.categoryKey]?.bgTint ??
        AppColors.primaryLight;

    final cadence = _cadenceLabel(rule);
    final nextDate = rule.isActive ? _nextDate(rule) : null;

    return Container(
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
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.autorenew_rounded,
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rule.label, style: AppTextStyles.bodyStrong),
                        const SizedBox(height: 2),
                        Text(
                          '${money.format(rule.amount)} · $cadence',
                          style: AppTextStyles.muted.copyWith(fontSize: 12),
                        ),
                        if (nextDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Next ${DateFormat('MMM d').format(nextDate)}',
                            style: AppTextStyles.mutedSmall.copyWith(
                              color: AppColors.inkMid,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!rule.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Paused',
                        style: AppTextStyles.mutedSmall.copyWith(
                          color: AppColors.inkMid,
                        ),
                      ),
                    ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.inkLight),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border, indent: 70),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    rule.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 18,
                    color: AppColors.inkMid,
                  ),
                  label: Text(
                    rule.isActive ? 'Pause' : 'Resume',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.inkMid,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    'Remove',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _cadenceLabel(RecurringExpense rule) {
    switch (rule.frequency) {
      case RecurrenceFrequency.weekly:
        return 'every week';
      case RecurrenceFrequency.biweekly:
        return 'every 2 weeks';
      case RecurrenceFrequency.monthly:
        return 'every month';
      case RecurrenceFrequency.custom:
        final n = rule.intervalDays ?? 0;
        return 'every $n days';
    }
  }

  static DateTime? _nextDate(RecurringExpense rule) {
    try {
      final now = DateTime.now();
      return nextOccurrence(rule, DateTime(now.year, now.month, now.day));
    } catch (_) {
      return null;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.autorenew_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text('No recurring expenses yet', style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'Add Netflix, Spotify, gym, or any subscription that posts on a schedule.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Add subscription',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
