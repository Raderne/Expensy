import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/recurring_expense.dart';

class FrequencyPicker extends StatelessWidget {
  final RecurrenceFrequency value;
  final ValueChanged<RecurrenceFrequency> onChanged;

  const FrequencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: RecurrenceFrequency.values.map((f) {
          final selected = f == value;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (selected) return;
                HapticFeedback.selectionClick();
                onChanged(f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x14000C22),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  f.label,
                  style: AppTextStyles.labelStrong.copyWith(
                    fontSize: 12.5,
                    color: selected ? AppColors.ink : AppColors.inkMid,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
