import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/analytics_breakdown.dart';

/// Per-category spend: colour dot, label, amount and a proportional bar.
///
/// On an expanded window this is the *only* breakdown on screen — the donut's
/// legend is dropped there because it showed a strict subset of what these rows
/// already show — so the rows double as the filter control for the companion
/// transactions pane. Same [selectedCategoryId] / [onSelect] contract as
/// `DonutLegend`, which keeps the compact and expanded behaviour interchangeable.
class SpendingBars extends StatelessWidget {
  final List<BreakdownItem> items;

  /// When set, highlights the matching row.
  final String? selectedCategoryId;

  /// Optional tap handler. Rows stay read-only when null.
  final ValueChanged<String>? onSelect;

  const SpendingBars({
    super.key,
    required this.items,
    this.selectedCategoryId,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _BarRow(
            item: items[i],
            selected: items[i].categoryId == selectedCategoryId,
            onTap: onSelect == null
                ? null
                : () => onSelect!(items[i].categoryId),
          ),
          if (i < items.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final BreakdownItem item;
  final bool selected;
  final VoidCallback? onTap;

  const _BarRow({required this.item, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.simpleCurrency(
      decimalDigits: 0,
    ).format(item.amount);
    final row = Column(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  color: AppColors.ink,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

    if (onTap == null) return row;

    // The Semantics sits *inside* the InkWell: the ink well contributes the
    // button role and tap action, and this replaces the three separate strings
    // a screen reader would otherwise read out of the row.
    return Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: Semantics(
          button: true,
          selected: selected,
          label: '${item.label}, $amount, ${(item.pct * 100).round()} percent',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: row,
          ),
        ),
      ),
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
          // TweenAnimationBuilder gives us a free "0 -> target on first build"
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
