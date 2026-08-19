import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/date_grouping.dart';
import 'swipeable_transaction_row.dart';

/// One day's transactions: the date label above a single rounded card holding
/// the rows. Shared by the full Transactions list and by the shell's companion
/// activity feed, so a row looks and behaves the same in both.
class DayGroupCard extends StatelessWidget {
  final TransactionGroup group;
  final Future<void> Function(String id) onDelete;

  const DayGroupCard({super.key, required this.group, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(group.label, style: AppTextStyles.groupLabel),
        ),
        GlassCard(
          radius: 16,
          strong: true,
          blur: 14,
          child: Column(
            children: [
              for (int i = 0; i < group.transactions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 68,
                    color: AppColors.glassBorder,
                  ),
                SwipeableTransactionRow(
                  transaction: group.transactions[i],
                  onDelete: () => onDelete(group.transactions[i].id),
                  onTap: group.transactions[i].isShared
                      ? () => context.push('/shared')
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
