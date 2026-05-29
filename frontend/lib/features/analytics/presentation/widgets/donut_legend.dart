import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/analytics_breakdown.dart';

class DonutLegend extends StatelessWidget {
  final List<BreakdownItem> items;

  const DonutLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items) ...[
          _LegendRow(item: item),
          if (item != items.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final BreakdownItem item;
  const _LegendRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Text(
          item.label,
          style: AppTextStyles.label.copyWith(
            fontSize: 13,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(item.pct * 100).round()}%',
          style: AppTextStyles.label.copyWith(
            fontSize: 12,
            color: AppColors.inkLight,
          ),
        ),
      ],
    );
  }
}
