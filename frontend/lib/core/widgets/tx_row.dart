import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A single transaction row: tinted square avatar + label/note + signed amount.
/// Amount is positive for income (green) and negative for expense (ink).
class TxRow extends StatelessWidget {
  final String label;
  final String? note;
  final double amount;
  final String categoryAbbr;
  final Color categoryColor;
  final Color categoryBg;

  const TxRow({
    super.key,
    required this.label,
    required this.amount,
    required this.categoryAbbr,
    required this.categoryColor,
    required this.categoryBg,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = amount >= 0;
    final money = NumberFormat.simpleCurrency(locale: 'en_US');
    final sign = isIncome ? '+' : '-';
    final formatted = '$sign${money.format(amount.abs())}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              categoryAbbr,
              style: AppTextStyles.labelStrong.copyWith(color: categoryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyStrong),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: AppTextStyles.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatted,
            style: AppTextStyles.bodyStrong.copyWith(
              color: isIncome ? AppColors.success : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
