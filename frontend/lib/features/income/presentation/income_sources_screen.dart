import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../application/income_controller.dart';
import '../data/income_repository.dart';
import '../domain/recurring_income.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../transactions/application/transactions_controller.dart';
import 'widgets/edit_recurring_income_sheet.dart';

class IncomeSourcesScreen extends ConsumerWidget {
  const IncomeSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeControllerProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeroGradient(
              padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      HeaderBackButton.onHero(onTap: () => context.pop()),
                      const Spacer(),
                      Text(
                        'Income sources',
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
                    'Recurring jobs are posted automatically on their payday.',
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
          incomeAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(incomeControllerProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
            data: (sources) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              sliver: SliverList.list(
                children: [
                  if (sources.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'No recurring income yet. Add your salary or other regular pay.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.inkMid,
                        ),
                      ),
                    )
                  else
                    ...sources.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SourceCard(
                          source: s,
                          onEdit: () => _openEdit(context, s),
                          onToggle: () => _toggleActive(ref, s),
                          onDelete: () => _confirmDelete(context, ref, s),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _AddButton(onTap: () => _openAdd(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => const EditRecurringIncomeSheet(),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income source added'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openEdit(BuildContext context, RecurringIncome source) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => EditRecurringIncomeSheet(existing: source),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income source updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _toggleActive(WidgetRef ref, RecurringIncome source) async {
    try {
      await ref
          .read(incomeRepositoryProvider)
          .updateRecurring(id: source.id, isActive: !source.isActive);
      ref.invalidate(incomeControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(transactionsControllerProvider);
    } on IncomeApiException catch (e) {
      // ignore: use_build_context_synchronously — no context here
      debugPrint(e.message);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringIncome source,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove source?', style: AppTextStyles.titleM),
        content: Text(
          'Future automatic posts from "${source.label}" will stop. Past income stays in your history.',
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
      await ref.read(incomeRepositoryProvider).deleteRecurring(source.id);
      ref.invalidate(incomeControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(transactionsControllerProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Income source removed')));
      }
    } on IncomeApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _SourceCard extends StatelessWidget {
  final RecurringIncome source;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SourceCard({
    required this.source,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(source.label, style: AppTextStyles.bodyStrong),
                        const SizedBox(height: 2),
                        Text(
                          '${money.format(source.amount)}/mo · Day ${source.dayOfMonth}',
                          style: AppTextStyles.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!source.isActive)
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkLight,
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border,
            indent: 68,
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    source.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 18,
                    color: AppColors.inkMid,
                  ),
                  label: Text(
                    source.isActive ? 'Pause' : 'Resume',
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
                'Add income source',
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
