import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/dashboard_summary.dart';

class BalanceCard extends StatelessWidget {
  final DashboardSummary summary;

  /// Lay the card out horizontally — balance on the left, the income/expenses
  /// boxes beside it — instead of stacking them. Used by the expanded header
  /// band, where height is the scarce dimension and width is not.
  final bool wide;

  const BalanceCard({super.key, required this.summary, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(locale: 'en_US');

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: wide ? _wide(money) : _stacked(money),
        ),
      ),
    );
  }

  Widget _stacked(NumberFormat money) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Amount(summary: summary, money: money),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'INCOME',
              amount: summary.income,
              money: money,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatBox(
              label: 'EXPENSES',
              amount: summary.expenses,
              money: money,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _wide(NumberFormat money) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        flex: 5,
        child: _Amount(summary: summary, money: money),
      ),
      const SizedBox(width: 18),
      Expanded(
        flex: 4,
        child: Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'INCOME',
                amount: summary.income,
                money: money,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                label: 'EXPENSES',
                amount: summary.expenses,
                money: money,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Amount extends StatelessWidget {
  final DashboardSummary summary;
  final NumberFormat money;

  const _Amount({required this.summary, required this.money});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BALANCE',
          style: AppTextStyles.mutedSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            money.format(summary.net),
            maxLines: 1,
            style: AppTextStyles.heroAmount.copyWith(
              fontSize: 38,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All-time ${money.format(summary.balance)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.mutedSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat money;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.mutedSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money.format(amount),
              maxLines: 1,
              style: AppTextStyles.titleS.copyWith(
                color: Colors.white,
                fontSize: 16.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
