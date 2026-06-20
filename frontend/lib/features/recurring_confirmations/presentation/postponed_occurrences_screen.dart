import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../income/application/income_controller.dart';
import '../../recurring_expenses/application/recurring_expenses_controller.dart';
import '../../recurring_expenses/application/upcoming_bills_controller.dart';
import '../../transactions/application/transactions_controller.dart';
import '../application/pending_occurrences_controller.dart';
import '../application/postponed_occurrences_controller.dart';
import '../data/recurring_confirmations_repository.dart';
import '../domain/pending_occurrence.dart';
import 'confirmation_modal.dart';

/// Lets the user act on items they pushed to a later day: confirm early (the
/// income arrived / the expense went through) or reschedule again. Postpone
/// never changes the underlying recurrence schedule.
class PostponedOccurrencesScreen extends ConsumerWidget {
  const PostponedOccurrencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(postponedOccurrencesControllerProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeroGradient(
              padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      HeaderBackButton.onHero(onTap: () => context.pop()),
                      const Spacer(),
                      Text(
                        'Postponed',
                        style: AppTextStyles.titleM.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirm these when the money moves, or push them again.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
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
                      ref.invalidate(postponedOccurrencesControllerProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
            data: (items) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              sliver: items.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyState())
                  : SliverList.list(
                      children: items
                          .map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PostponedCard(
                                occurrence: o,
                                onConfirm: () => _confirm(context, ref, o),
                                onReschedule: () =>
                                    _reschedule(context, ref, o),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    PendingOccurrence o,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(recurringConfirmationsRepositoryProvider).confirm(o.id);
      HapticFeedback.mediumImpact();
      _invalidate(ref);
      messenger.showSnackBar(
        SnackBar(
          content: Text(o.isIncome ? 'Income confirmed' : 'Expense confirmed'),
          backgroundColor: AppColors.success,
        ),
      );
    } on RecurringConfirmationsApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _reschedule(
    BuildContext context,
    WidgetRef ref,
    PendingOccurrence o,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showConfirmationModal(context, occurrence: o);
    if (result == null) return;
    try {
      switch (result) {
        case ConfirmResult(:final amount):
          await ref
              .read(recurringConfirmationsRepositoryProvider)
              .confirm(o.id, amount: amount);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                o.isIncome ? 'Income confirmed' : 'Expense confirmed',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        case PostponeResult(:final date):
          await ref
              .read(recurringConfirmationsRepositoryProvider)
              .postpone(o.id, date);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Moved to ${DateFormat('MMM d').format(date)}'),
              backgroundColor: AppColors.primary,
            ),
          );
      }
      HapticFeedback.selectionClick();
      _invalidate(ref);
    } on RecurringConfirmationsApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(postponedOccurrencesControllerProvider);
    ref.invalidate(pendingOccurrencesControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(upcomingBillsControllerProvider);
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(incomeControllerProvider);
    ref.invalidate(recurringExpensesControllerProvider);
  }
}

class _PostponedCard extends StatelessWidget {
  final PendingOccurrence occurrence;
  final VoidCallback onConfirm;
  final VoidCallback onReschedule;

  const _PostponedCard({
    required this.occurrence,
    required this.onConfirm,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = occurrence.isIncome;
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final color = isIncome ? AppColors.success : AppColors.danger;
    final tint = isIncome ? AppColors.successLight : AppColors.dangerLight;
    final dueLabel = DateFormat('EEE, MMM d').format(occurrence.dueAt);
    final scheduledLabel = DateFormat('MMM d').format(occurrence.scheduledFor);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Now $dueLabel · was due $scheduledLabel',
                        style: AppTextStyles.muted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${money.format(occurrence.amount)}',
                  style: AppTextStyles.bodyStrong.copyWith(color: color),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border, indent: 70),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  label: Text(
                    'Confirm',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onReschedule,
                  icon: Icon(
                    Icons.event_repeat_rounded,
                    size: 18,
                    color: AppColors.inkMid,
                  ),
                  label: Text(
                    'Reschedule',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.inkMid,
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
              Icons.event_available_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text('Nothing postponed', style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'Items you push to a later day from the confirmation prompt show up here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
