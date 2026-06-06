import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/domain/recent_transaction.dart';

/// What the user chose on the post-save success popup.
enum SuccessAction { addAnother, done }

/// Centered "Expense Saved!" confirmation that scales + fades in over the
/// Add Expense modal. Returns the chosen [SuccessAction], or null if dismissed
/// by tapping the barrier.
Future<SuccessAction?> showSuccessPopup(
  BuildContext context, {
  required RecentTransaction transaction,
}) {
  return showGeneralDialog<SuccessAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Expense saved',
    barrierColor: const Color(0x66000C22),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => _SuccessCard(transaction: transaction),
    transitionBuilder: (context, animation, _, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(scale),
          child: child,
        ),
      );
    },
  );
}

class _SuccessCard extends StatelessWidget {
  final RecentTransaction transaction;
  const _SuccessCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = transaction.amount.abs().toStringAsFixed(2);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000C22),
                  blurRadius: 28,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Expense Saved!', style: AppTextStyles.titleL),
                const SizedBox(height: 6),
                Text(
                  '-\$$amount · ${transaction.category.label}',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _PopupButton(
                        label: 'Add Another',
                        filled: false,
                        onTap: () =>
                            Navigator.of(context).pop(SuccessAction.addAnother),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PopupButton(
                        label: 'Done',
                        filled: true,
                        onTap: () =>
                            Navigator.of(context).pop(SuccessAction.done),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PopupButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: AppColors.border),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.27),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelStrong.copyWith(
            fontSize: 14.5,
            color: filled ? Colors.white : AppColors.inkMid,
          ),
        ),
      ),
    );
  }
}
