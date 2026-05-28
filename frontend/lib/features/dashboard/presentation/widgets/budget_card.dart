import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/dashboard_summary.dart';

class BudgetCard extends StatelessWidget {
  final BudgetInfo budget;

  const BudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B228E).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Monthly Budget', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
              if (budget.isSet)
                Text(
                  '${budget.pct}% used',
                  style: AppTextStyles.labelStrong.copyWith(color: AppColors.accent, fontSize: 12.5),
                )
              else
                Text('Not set', style: AppTextStyles.label.copyWith(color: AppColors.inkLight)),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(pct: budget.pct),
          const SizedBox(height: 5),
          Text(
            budget.isSet
                ? '${money.format(budget.spent)} of ${money.format(budget.amount)} spent this month'
                : 'Set a budget to track your spending',
            style: AppTextStyles.mutedSmall,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int pct;
  const _ProgressBar({required this.pct});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = constraints.maxWidth * (pct.clamp(0, 100) / 100);
        return SizedBox(
          height: 7,
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const SizedBox.expand(),
              ),
              if (pct > 0)
                Container(
                  width: fillWidth,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
