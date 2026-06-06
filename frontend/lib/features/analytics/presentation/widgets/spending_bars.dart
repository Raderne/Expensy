import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/analytics_breakdown.dart';

class SpendingBars extends StatelessWidget {
  final List<BreakdownItem> items;

  const SpendingBars({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _BarRow(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final BreakdownItem item;
  const _BarRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.simpleCurrency(
      decimalDigits: 0,
    ).format(item.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.colorValue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              amount,
              style: AppTextStyles.labelStrong.copyWith(
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _AnimatedBar(target: item.pct.clamp(0.0, 1.0), color: item.colorValue),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final double target;
  final Color color;

  const _AnimatedBar({required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 6, color: AppColors.border),
          // TweenAnimationBuilder gives us a free "0 → target on first build"
          // animation, plus implicit transitions when the target changes (e.g.
          // when the user switches months).
          LayoutBuilder(
            builder: (_, c) => TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: target),
              builder: (_, value, _) =>
                  Container(height: 6, width: c.maxWidth * value, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
