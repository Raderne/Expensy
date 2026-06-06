import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Three compact cards: Income, Expenses, and Net for the selected month.
class SummaryRow extends StatelessWidget {
  final double income;
  final double expenses;
  final double net;

  const SummaryRow({
    super.key,
    required this.income,
    required this.expenses,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final netFg = net >= 0 ? AppColors.primary : AppColors.danger;
    final netBg = net >= 0 ? AppColors.primaryLight : AppColors.dangerLight;
    final netSign = net >= 0 ? '+' : '-';

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
        const SizedBox(width: 8),
        Expanded(
          child: _Card(
            label: 'EXPENSES',
            value: expenses,
            fg: AppColors.danger,
            bg: AppColors.dangerLight,
            sign: '-',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Card(
            label: 'NET',
            value: net.abs(),
            fg: netFg,
            bg: netBg,
            sign: netSign,
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
    final money = NumberFormat.simpleCurrency(
      locale: 'en_US',
      decimalDigits: 0,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              fontSize: 9.5,
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$sign${money.format(value)}',
              style: AppTextStyles.titleM.copyWith(color: fg, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
