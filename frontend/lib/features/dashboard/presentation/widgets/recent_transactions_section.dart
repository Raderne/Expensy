import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tx_row.dart';
import '../../domain/recent_transaction.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<RecentTransaction> transactions;

  const RecentTransactionsSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: AppTextStyles.titleS),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: Text(
                'See all →',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (transactions.isEmpty)
          _EmptyState()
        else
          ...transactions.map(
            (t) => TxRow(
              label: t.category.label,
              note: t.note,
              amount: t.amount,
              categoryAbbr: t.category.abbr,
              categoryColor: t.category.colorValue,
              categoryBg: t.category.bgTintValue,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
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
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text('No transactions yet', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4),
            Text(
              'Add your first expense to get started.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/add'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add your first expense',
                  style: AppTextStyles.labelStrong.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
