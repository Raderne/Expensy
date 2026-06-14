import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tx_row.dart';
import '../../domain/transaction.dart';
import 'delete_transaction_dialog.dart';

/// Swipe-left-to-delete row. Designed to live inside a [ClipRRect] card so
/// the swipe reveal is clipped by the card's border radius. Recurring income
/// rows are read-only and not dismissible.
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
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TxRow(
        label: transaction.category.label,
        note: transaction.note,
        amount: transaction.amount,
        categoryAbbr: transaction.category.abbr,
        categoryColor: transaction.category.colorValue,
        categoryBg: transaction.category.bgTintValue,
        pending: transaction.pending,
      ),
    );

    // A pending (not-yet-synced) row can't be deleted until it lands server-side.
    if (transaction.isRecurringIncome || transaction.pending) return row;

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
      background: _DeleteBackground(),
      child: row,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFECACA), Color(0xFFFEE2E2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(height: 3),
          Text(
            'Delete',
            style: AppTextStyles.mutedSmall.copyWith(
              color: AppColors.danger,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
