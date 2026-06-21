import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/recent_transaction.dart';

/// Recent activity, presented as a first-class dashboard card so it reads as a
/// peer of the Budget / Upcoming / Postponed modules rather than a bare list.
/// A hairline-ruled ledger: tinted category avatar, label + note, then the
/// signed amount with a relative date beneath it.
class RecentTransactionsSection extends StatelessWidget {
  final List<RecentTransaction> transactions;

  const RecentTransactionsSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            child: Row(
              children: [
                Text('Recent activity', style: AppTextStyles.titleS),
                const Spacer(),
                if (transactions.isNotEmpty)
                  _SeeAllButton(onTap: () => context.go('/transactions')),
              ],
            ),
          ),
          if (transactions.isEmpty)
            const _EmptyState()
          else
            Divider(height: 1, thickness: 1, color: AppColors.border),
          if (transactions.isNotEmpty)
            ...List.generate(transactions.length, (i) {
              final t = transactions[i];
              return Column(
                children: [
                  _RecentTile(transaction: t),
                  if (i != transactions.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 72,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Text(
                'See all',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final RecentTransaction transaction;
  const _RecentTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.amount >= 0;
    final money = NumberFormat.simpleCurrency(locale: 'en_US');
    final formatted = '${isIncome ? '+' : '-'}${money.format(t.amount.abs())}';
    final hasNote = t.note != null && t.note!.isNotEmpty;

    return Opacity(
      opacity: t.pending ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.category.bgTintValue,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                t.category.abbr,
                style: AppTextStyles.labelStrong.copyWith(
                  color: t.category.colorValue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                      if (t.pending) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.inkLight,
                        ),
                      ],
                    ],
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.note!,
                      style: AppTextStyles.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatted,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: isIncome ? AppColors.success : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeDate(t.occurredAt),
                  style: AppTextStyles.mutedSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '$diff days ago';
    return DateFormat('MMM d').format(d);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
            Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/add'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  child: Text(
                    'Add your first expense',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: Colors.white,
                    ),
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
