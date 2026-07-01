import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../shared/domain/expense_split_draft.dart';
import '../../../shared/presentation/widgets/split_editor.dart';

/// Bottom sheet that hosts the reusable [SplitEditor]. Edits stream out live via
/// [onChanged] (the add-expense controller stores them), so dismissing the sheet
/// simply closes it — nothing to confirm.
Future<void> showSplitSheet(
  BuildContext context, {
  required double amount,
  required List<ExpenseSplitDraft> initial,
  required ValueChanged<List<ExpenseSplitDraft>> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (_) =>
        _SplitSheet(amount: amount, initial: initial, onChanged: onChanged),
  );
}

class _SplitSheet extends StatelessWidget {
  final double amount;
  final List<ExpenseSplitDraft> initial;
  final ValueChanged<List<ExpenseSplitDraft>> onChanged;

  const _SplitSheet({
    required this.amount,
    required this.initial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.scrim,
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                  child: SplitEditor(
                    amount: amount,
                    initial: initial,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: _DoneButton(onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.27),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Done',
          style: AppTextStyles.labelStrong.copyWith(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
