import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Reusable bottom sheet that lists [months] (YYYY-MM, newest first) and
/// returns the selected one. Returns null on dismiss.
Future<String?> showMonthPickerSheet(
  BuildContext context, {
  required List<String> months,
  required String selected,
}) {
  // If we have no months yet, surface the currently-selected one so the user
  // can still see the active state.
  final list = months.isEmpty ? [selected] : months;
  return showAppBottomSheet<String>(
    context: context,
    builder: (_) => _MonthPickerSheet(months: list, selected: selected),
  );
}

class _MonthPickerSheet extends StatelessWidget {
  final List<String> months;
  final String selected;

  const _MonthPickerSheet({required this.months, required this.selected});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.55;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [Text('Pick a month', style: AppTextStyles.titleM)],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: months.length,
                  itemBuilder: (_, i) {
                    final m = months[i];
                    return _MonthTile(
                      month: m,
                      selected: m == selected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop(m);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final String month; // YYYY-MM
  final bool selected;
  final VoidCallback onTap;

  const _MonthTile({
    required this.month,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = month.split('-');
    final label = parts.length == 2
        ? DateFormat(
            'MMMM yyyy',
          ).format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
        : month;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: selected ? AppColors.primary : AppColors.ink,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
