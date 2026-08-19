import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../application/analytics_controller.dart';
import 'month_picker_sheet.dart';

/// "Analytics" + the month chip. Unlike Transactions this destination has never
/// had a gradient hero, so the band stays flat on the ambient background.
///
/// On an expanded window this is the only month control on screen: the
/// companion transactions pane follows it (the shell syncs the two controllers)
/// rather than carrying a second navigator of its own.
class AnalyticsHeaderBar extends ConsumerWidget {
  const AnalyticsHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider).value;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pageInsetOf(context),
        4,
        pageInsetOf(context),
        14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Analytics', style: AppTextStyles.titleL),
          if (state != null)
            _MonthChip(
              label: monthLabel(state.month),
              onTap: () => _pickMonth(context, ref, state),
            )
          else
            const ShimmerBox(height: 34, width: 120, radius: 11),
        ],
      ),
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    AnalyticsState state,
  ) async {
    final picked = await showMonthPickerSheet(
      context,
      months: state.availableMonths,
      selected: state.month,
    );
    if (picked != null && picked != state.month) {
      await ref.read(analyticsControllerProvider.notifier).setMonth(picked);
    }
  }
}

class _MonthChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MonthChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 11,
      shadow: false,
      strong: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelStrong.copyWith(
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.inkMid,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// `2026-08` -> `August 2026`.
String monthLabel(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat('MMMM yyyy').format(dt);
}
