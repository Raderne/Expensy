import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Centered amount: tiny "AMOUNT" caption, "$" + value, blue underline.
/// Mirrors design/Expensy.html lines 275-282.
class AmountDisplay extends StatelessWidget {
  final String value;

  const AmountDisplay({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'AMOUNT',
          style: AppTextStyles.muted.copyWith(letterSpacing: 0.4),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 4),
              child: Text(
                '\$',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.inkMid,
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(value, style: AppTextStyles.addAmount),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 72,
          height: 2.5,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
