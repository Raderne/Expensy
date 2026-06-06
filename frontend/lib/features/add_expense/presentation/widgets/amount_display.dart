import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Formats a raw numeric string with thousand-separator commas.
/// Preserves a trailing decimal point and any decimal digits as-is so the
/// numpad input feels live while the user is typing (e.g. "1000." stays "1,000.").
String _formatAmount(String raw) {
  if (raw.isEmpty) return raw;
  final dotIndex = raw.indexOf('.');
  final intPart = dotIndex >= 0 ? raw.substring(0, dotIndex) : raw;
  final decPart = dotIndex >= 0 ? raw.substring(dotIndex) : '';
  final formatted = intPart.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return '$formatted$decPart';
}

/// Compact single-row amount display.
///
/// Layout: [AMOUNT badge] | [$] [value right-aligned]
/// Sits inside a full-width pill that matches the screen's 18 px side padding.
class AmountDisplay extends StatelessWidget {
  final String value;

  const AmountDisplay({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'AMOUNT',
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Divider
            Container(width: 1, height: 28, color: AppColors.border),
            const SizedBox(width: 12),
            // Currency symbol
            Text(
              '\$',
              style: AppTextStyles.body.copyWith(
                color: AppColors.inkLight,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            // Amount value — right-aligned, formatted with thousand separators
            Expanded(
              child: Text(
                _formatAmount(value),
                textAlign: TextAlign.right,
                style: AppTextStyles.titleL.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
