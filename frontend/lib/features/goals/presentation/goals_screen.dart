import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../application/goals_controller.dart';
import '../data/goals_repository.dart';
import '../domain/goal.dart';
import 'widgets/add_funds_sheet.dart';
import 'widgets/edit_goal_sheet.dart';
import 'widgets/goal_estimate_sheet.dart';
import 'widgets/rollover_prompt.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsControllerProvider);
    final topInset = MediaQuery.paddingOf(context).top;
    final goals = goalsAsync.value ?? const <Goal>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Hero(topInset: topInset, goals: goals),
            ),
            const SliverToBoxAdapter(child: RolloverPrompt()),
            goalsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  onRetry: () =>
                      ref.read(goalsControllerProvider.notifier).refresh(),
                ),
              ),
              data: (list) => SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    if (list.isEmpty)
                      const _EmptyState()
                    else
                      ...list.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(
                            goal: g,
                            onEdit: () => _openEdit(context, g),
                            onDelete: () => _confirmDelete(context, ref, g),
                            onAddFunds: () => _openAddFunds(context, g),
                            onEstimate: () => _openEstimate(context, g),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _AddGoalButton(onTap: () => _openAdd(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final ok = await showEditSheet<bool>(context, (_) => const EditGoalSheet());
    if (ok == true && context.mounted) _toast(context, 'Goal created');
  }

  Future<void> _openEdit(BuildContext context, Goal goal) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => EditGoalSheet(existing: goal),
    );
    if (ok == true && context.mounted) _toast(context, 'Goal updated');
  }

  Future<void> _openAddFunds(BuildContext context, Goal goal) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => AddFundsSheet(goal: goal),
    );
    if (ok == true && context.mounted) _toast(context, 'Funds added');
  }

  Future<void> _openEstimate(BuildContext context, Goal goal) async {
    await GoalEstimateSheet.show(context, goal);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete goal?', style: AppTextStyles.titleM),
        content: Text(
          'This removes "${goal.name}" and its saved progress. This can’t be undone.',
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
              'Delete',
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
      await ref.read(goalsRepositoryProvider).delete(goal.id);
      ref.invalidate(goalsControllerProvider);
      if (context.mounted) _toast(context, 'Goal deleted');
    } on GoalsApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final double topInset;
  final List<Goal> goals;

  const _Hero({required this.topInset, required this.goals});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(locale: 'en_US');
    final count = goals.length;
    final monthly = goals.monthlySavings;

    return DecoratedBox(
      decoration: HeroGradient.decoration,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          pageInsetOf(context),
          topInset + 8,
          pageInsetOf(context),
          24,
        ),
        child: Column(
          children: [
            Row(
              children: [
                HeaderBackButton.onHero(onTap: () => context.pop()),
                const Spacer(),
                Text(
                  'Goals',
                  style: AppTextStyles.titleM.copyWith(color: Colors.white),
                ),
                const Spacer(),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'TOTAL SAVED',
              style: AppTextStyles.mutedSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              money.format(goals.totalSaved),
              style: AppTextStyles.heroAmount.copyWith(
                fontSize: 38,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              count == 0
                  ? 'No goals yet'
                  : monthly > 0
                  ? '${money.format(monthly)}/mo to stay on track · $count ${count == 1 ? 'goal' : 'goals'}'
                  : '$count ${count == 1 ? 'goal' : 'goals'}',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal card ───────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddFunds;
  final VoidCallback onEstimate;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onAddFunds,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final color = goal.colorValue;

    return GlassCard(
      radius: 18,
      blur: 24,
      tint: color,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(goal.iconData, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${money.format(goal.savedAmount)} of ${money.format(goal.targetAmount)}',
                      style: AppTextStyles.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              _IconAction(
                icon: Icons.edit_outlined,
                tooltip: 'Edit goal',
                onTap: onEdit,
              ),
              _IconAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete goal',
                color: AppColors.danger,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ProgressBar(progress: goal.progress, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  '${goal.pct}%',
                  style: AppTextStyles.labelStrong.copyWith(
                    color: goal.isComplete ? AppColors.success : color,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: goal.targetDate != null
                    ? Text(
                        'Target · ${DateFormat('MMM yyyy').format(goal.targetDate!)}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.mutedSmall,
                      )
                    : goal.isComplete
                    ? Text(
                        'Goal reached 🎉',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.mutedSmall.copyWith(
                          color: AppColors.success,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              _EstimateButton(onTap: onEstimate),
              const SizedBox(width: 8),
              _AddFundsButton(color: color, onTap: onAddFunds),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fill = constraints.maxWidth * progress.clamp(0.0, 1.0);
        return SizedBox(
          height: 8,
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const SizedBox.expand(),
              ),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: fill),
                builder: (_, value, _) => Container(
                  width: value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.75), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 19, color: color ?? AppColors.inkLight),
    );
  }
}

class _AddFundsButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _AddFundsButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                'Add funds',
                style: AppTextStyles.labelStrong.copyWith(
                  color: color,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EstimateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Estimate',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add button / states ─────────────────────────────────────────────────────

class _AddGoalButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGoalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'New goal',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text('No goals yet', style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'Create a savings goal and track your progress toward it.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

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
            Text('Could not load goals', style: AppTextStyles.bodyStrong),
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
