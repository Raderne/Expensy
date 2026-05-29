import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tx_row.dart';
import '../../domain/transaction.dart';
import 'delete_transaction_dialog.dart';

/// Swipe left to reveal delete. Recurring income rows are not dismissible.
class SwipeableTransactionRow extends StatelessWidget {
  final Transaction transaction;
  final Future<void> Function() onDelete;

  const SwipeableTransactionRow({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final row = TxRow(
      label: transaction.category.label,
      note: transaction.note,
      amount: transaction.amount,
      categoryAbbr: transaction.category.abbr,
      categoryColor: transaction.category.colorValue,
      categoryBg: transaction.category.bgTintValue,
    );

    if (transaction.isRecurringIncome) {
      return row;
    }

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDeleteTransactionDialog(
          context,
          transaction: transaction,
        );
        if (!confirmed) return false;
        try {
          await onDelete();
          HapticFeedback.mediumImpact();
          return true;
        } catch (_) {
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 4),
          ],
        ),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: row,
        ),
      ),
    );
  }
}
