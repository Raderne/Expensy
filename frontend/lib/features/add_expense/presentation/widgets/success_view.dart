import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/domain/recent_transaction.dart';

/// Post-save success state: green check tile + headline + "Add Another" pill.
/// Mirrors design/Expensy.html lines 243-261.
class SuccessView extends StatelessWidget {
  final RecentTransaction transaction;
  final VoidCallback onAddAnother;

  const SuccessView({
    super.key,
    required this.transaction,
    required this.onAddAnother,
  });

  @override
  Widget build(BuildContext context) {
    final amount = transaction.amount.abs().toStringAsFixed(2);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Expense Saved!',
            style: AppTextStyles.titleL,
          ),
          const SizedBox(height: 6),
          Text(
            '-\$$amount · ${transaction.category.label}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onAddAnother,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.27),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Add Another',
                style: AppTextStyles.labelStrong.copyWith(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
