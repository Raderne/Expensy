import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/dashboard_summary.dart';

class BalanceCard extends StatelessWidget {
  final DashboardSummary summary;

  const BalanceCard({super.key, required this.summary});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BALANCE',
                style: AppTextStyles.mutedSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.58),
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                money.format(summary.net),
                style: AppTextStyles.heroAmount.copyWith(
                  fontSize: 38,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All-time ${money.format(summary.balance)}',
                style: AppTextStyles.mutedSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
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
          ),
        ),
      ),
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
          Text(
            money.format(amount),
            style: AppTextStyles.titleS.copyWith(
              color: Colors.white,
              fontSize: 16.5,
            ),
          ),
        ],
      ),
    );
  }
}
