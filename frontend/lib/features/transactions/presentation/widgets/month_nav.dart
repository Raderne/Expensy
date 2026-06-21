import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Month picker: ‹ MonthYYYY › — chevrons disable at the edges of the user's
/// transaction-history range.
///
/// Set [onHero] when placed over the blue hero gradient so the text and chevron
/// buttons switch to a white-on-translucent treatment.
class MonthNav extends StatelessWidget {
  final String month; // YYYY-MM
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool onHero;

  const MonthNav({
    super.key,
    required this.month,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    this.onHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChevronButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrev,
          onTap: onPrev,
          onHero: onHero,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _label(month),
            textAlign: TextAlign.center,
            style: onHero
                ? AppTextStyles.titleM.copyWith(color: Colors.white)
                : AppTextStyles.titleS,
          ),
        ),
        const SizedBox(width: 10),
        _ChevronButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onTap: onNext,
          onHero: onHero,
        ),
      ],
    );
  }

  static String _label(String month) {
    // month is YYYY-MM; we parse to a real DateTime so DateFormat handles
    // localization correctly if we ever add l10n.
    final parts = month.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMMM yyyy').format(dt);
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool onHero;

  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.onHero,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color borderColor;
    if (onHero) {
      fg = Colors.white.withValues(alpha: enabled ? 0.95 : 0.4);
      bg = Colors.white.withValues(alpha: 0.16);
      borderColor = Colors.white.withValues(alpha: 0.22);
    } else {
      fg = enabled ? AppColors.inkMid : AppColors.inkFaint;
      bg = AppColors.surface;
      borderColor = AppColors.border;
    }
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: fg, size: 18),
      ),
    );
  }
}
