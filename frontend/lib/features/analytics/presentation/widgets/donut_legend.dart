import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/analytics_breakdown.dart';

class DonutLegend extends StatelessWidget {
  final List<BreakdownItem> items;

  /// When set, highlights the matching row (two-pane category filter).
  final String? selectedCategoryId;

  /// Optional tap handler — used on expanded layouts to filter transactions.
  final ValueChanged<String>? onSelect;

  const DonutLegend({
    super.key,
    required this.items,
    this.selectedCategoryId,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items) ...[
          _LegendRow(
            item: item,
            selected: item.categoryId == selectedCategoryId,
            onTap: onSelect == null ? null : () => onSelect!(item.categoryId),
          ),
          if (item != items.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final BreakdownItem item;
  final bool selected;
  final VoidCallback? onTap;

  const _LegendRow({required this.item, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
        Flexible(
          child: Text(
            item.label,
            style: AppTextStyles.label.copyWith(
              fontSize: 13,
              color: AppColors.ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
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

    if (onTap == null) return row;

    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label}, ${(item.pct * 100).round()} percent',
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: row,
          ),
        ),
      ),
    );
  }
}
