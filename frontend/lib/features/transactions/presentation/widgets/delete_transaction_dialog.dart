import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/transaction.dart';

/// Branded confirmation before deleting a transaction.
Future<bool> showDeleteTransactionDialog(
  BuildContext context, {
  required Transaction transaction,
}) async {
  final money = NumberFormat.simpleCurrency(locale: 'en_US');
  final isIncome = transaction.amount >= 0;
  final sign = isIncome ? '+' : '-';
  final amountLabel =
      '$sign${money.format(transaction.amount.abs())}';
  final title = transaction.note?.isNotEmpty == true
      ? transaction.note!
      : transaction.category.label;

  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x66000C22),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000C22),
              blurRadius: 28,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Delete transaction?',
              style: AppTextStyles.titleM.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Remove "$title" ($amountLabel) from your history. This cannot be undone.',
              style: AppTextStyles.body.copyWith(color: AppColors.inkMid),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Keep',
                    fg: AppColors.inkMid,
                    bg: AppColors.background,
                    border: AppColors.border,
                    onTap: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: 'Delete',
                    fg: AppColors.danger,
                    bg: AppColors.dangerLight,
                    border: AppColors.dangerLight,
                    onTap: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelStrong.copyWith(color: fg, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
