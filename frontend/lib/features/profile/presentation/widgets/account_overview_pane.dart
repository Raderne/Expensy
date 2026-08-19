import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../../goals/application/goals_controller.dart';
import '../../../goals/domain/goal.dart';
import '../../../income/application/income_controller.dart';
import '../../../recurring_expenses/application/recurring_expenses_controller.dart';
import '../profile_settings_pane.dart';

/// Default companion pane on Me.
///
/// It replaces a "Choose a setting" placeholder that left half an 8-inch
/// display empty. This is deliberately read-only: every control it could offer
/// already exists as a row in the settings list beside it, and two copies of
/// the same button is worse than none. What it adds is the summary you would
/// otherwise have to open four separate screens to assemble.
class AccountOverviewPane extends ConsumerWidget {
  const AccountOverviewPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final dash = ref.watch(dashboardControllerProvider).value;
    final goals = ref.watch(goalsControllerProvider).value ?? const <Goal>[];
    final income = ref.watch(incomeControllerProvider).value;
    final recurring = ref.watch(recurringExpensesControllerProvider).value;
    final appVersion = ref.watch(appVersionProvider).value;

    final budget = dash?.summary.budget;
    final spentPct = (budget != null && budget.amount > 0)
        ? (budget.spent / budget.amount).clamp(0.0, 1.0)
        : 0.0;
    final goalsSaved = goals.totalSaved;
    final goalsTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        pageInsetOf(context),
        20,
        pageInsetOf(context),
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Text('At a glance', style: AppTextStyles.titleS),
        const SizedBox(height: 12),
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL BALANCE',
                style: AppTextStyles.mutedSmall.copyWith(
                  color: AppColors.inkMid,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  dash == null ? '—' : money.format(dash.summary.balance),
                  maxLines: 1,
                  style: AppTextStyles.titleL.copyWith(
                    fontSize: 32,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              if (dash != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'IN THIS MONTH',
                        value: money.format(dash.summary.income),
                        color: AppColors.successInk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStat(
                        label: 'OUT THIS MONTH',
                        value: money.format(dash.summary.expenses),
                        color: AppColors.dangerInk,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (budget != null && budget.isSet)
          _ProgressCard(
            title: 'Monthly budget',
            caption:
                '${money.format(budget.spent)} of ${money.format(budget.amount)} spent',
            progress: spentPct,
            color: spentPct >= 1 ? AppColors.danger : AppColors.primary,
          )
        else
          const _QuietCard(
            icon: Icons.savings_outlined,
            title: 'No monthly budget yet',
            caption: 'Set one from the list to track your spending pace.',
          ),
        const SizedBox(height: 12),
        if (goals.isNotEmpty && goalsTarget > 0)
          _ProgressCard(
            title: goals.length == 1 ? goals.first.name : 'Savings goals',
            caption:
                '${money.format(goalsSaved)} of ${money.format(goalsTarget)} saved',
            progress: (goalsSaved / goalsTarget).clamp(0.0, 1.0),
            color: AppColors.success,
          )
        else
          const _QuietCard(
            icon: Icons.flag_outlined,
            title: 'No savings goals yet',
            caption: 'Add one from the list to start putting money aside.',
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                icon: Icons.autorenew_rounded,
                label: 'Recurring',
                value: '${recurring?.activeCount ?? 0}',
                caption: recurring == null
                    ? '—'
                    : '${money.format(recurring.activeMonthlyTotal)}/mo',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CountCard(
                icon: Icons.payments_outlined,
                label: 'Income',
                value: '${income?.activeCount ?? 0}',
                caption: income == null
                    ? '—'
                    : '${money.format(income.activeMonthlyTotal)}/mo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            appVersion != null ? 'Expensy v$appVersion' : 'Expensy',
            style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkLight),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.mutedSmall.copyWith(
            color: AppColors.inkMid,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.titleS.copyWith(fontSize: 16.5, color: color),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String caption;
  final double progress;
  final Color color;

  const _ProgressCard({
    required this.title,
    required this.caption,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.labelStrong.copyWith(
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 7, color: AppColors.border),
                LayoutBuilder(
                  builder: (_, c) => TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: progress),
                    builder: (_, value, _) => Container(
                      height: 7,
                      width: c.maxWidth * value,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
          ),
        ],
      ),
    );
  }
}

class _QuietCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;

  const _QuietCard({
    required this.icon,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: AppTextStyles.mutedSmall.copyWith(
                    color: AppColors.inkMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const _CountCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.mutedSmall.copyWith(
                    color: AppColors.inkMid,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.titleM),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
          ),
        ],
      ),
    );
  }
}
