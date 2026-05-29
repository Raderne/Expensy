import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Two side-by-side cards: Income (green tint) and Expenses (red tint).
/// Mirrors design/Expensy.html lines 365-374.
class SummaryRow extends StatelessWidget {
  final double income;
  final double expenses;

  const SummaryRow({super.key, required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Card(
            label: 'INCOME',
            value: income,
            fg: AppColors.success,
            bg: AppColors.successLight,
            sign: '+',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Card(
            label: 'EXPENSES',
            value: expenses,
            fg: AppColors.danger,
            bg: AppColors.dangerLight,
            sign: '-',
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String label;
  final double value;
  final Color fg;
  final Color bg;
  final String sign;

  const _Card({
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
    required this.sign,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.muted.copyWith(
              fontSize: 10,
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$sign${money.format(value)}',
            style: AppTextStyles.titleM.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
