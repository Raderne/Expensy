import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/pending_occurrence.dart';

/// Outcome of the confirm/postpone modal. `null` (dismissed) is treated as
/// "decide later" by the caller.
sealed class ConfirmationResult {
  const ConfirmationResult();
}

class ConfirmResult extends ConfirmationResult {
  const ConfirmResult();
}

class PostponeResult extends ConfirmationResult {
  final DateTime date;
  const PostponeResult(this.date);
}

/// Same day next month, clamped to the month's last day (Jan 31 → Feb 28/29).
DateTime _nextMonth(DateTime from) {
  final targetMonth = from.month + 1;
  final year = from.year + (targetMonth > 12 ? 1 : 0);
  final month = targetMonth > 12 ? 1 : targetMonth;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, from.day.clamp(1, lastDay));
}

Future<ConfirmationResult?> showConfirmationModal(
  BuildContext context, {
  required PendingOccurrence occurrence,
}) {
  return showGeneralDialog<ConfirmationResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Confirm recurring item',
    barrierColor: AppColors.scrim,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => _ConfirmationCard(occurrence: occurrence),
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

class _ConfirmationCard extends StatefulWidget {
  final PendingOccurrence occurrence;
  const _ConfirmationCard({required this.occurrence});

  @override
  State<_ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends State<_ConfirmationCard> {
  bool _showPostponeOptions = false;

  PendingOccurrence get _occ => widget.occurrence;

  void _confirm() => Navigator.of(context).pop(const ConfirmResult());

  void _postponeTo(DateTime date) =>
      Navigator.of(context).pop(PostponeResult(date));

  Future<void> _pickDate() async {
    final tomorrow = _startOfDay(DateTime.now()).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null && mounted) _postponeTo(picked);
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final isIncome = _occ.isIncome;
    final color = isIncome ? AppColors.success : AppColors.danger;
    final tint = isIncome ? AppColors.successLight : AppColors.dangerLight;
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final amountText =
        '${isIncome ? '+' : '-'}${money.format(_occ.amount)}';
    final title = isIncome ? 'Income received?' : 'Expense paid?';
    final subtitle = isIncome
        ? 'Did you receive this income?'
        : 'Did you pay this expense?';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isIncome
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: color,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: AppTextStyles.titleL),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(color: AppColors.inkMid),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  amountText,
                  style: AppTextStyles.titleM.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_occ.label} · due ${DateFormat('MMM d').format(_occ.scheduledFor)}',
                  style: AppTextStyles.muted.copyWith(fontSize: 12.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                if (!_showPostponeOptions) ..._primaryButtons() else ..._postponeButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _primaryButtons() => [
    _ModalButton(
      label: 'Confirm',
      filled: true,
      onTap: _confirm,
    ),
    const SizedBox(height: 10),
    _ModalButton(
      label: 'Postpone',
      filled: false,
      onTap: () => setState(() => _showPostponeOptions = true),
    ),
  ];

  List<Widget> _postponeButtons() {
    final tomorrow = _startOfDay(DateTime.now()).add(const Duration(days: 1));
    final nextMonth = _nextMonth(_startOfDay(DateTime.now()));
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Remind me to decide on:',
          style: AppTextStyles.muted.copyWith(fontSize: 12.5),
        ),
      ),
      const SizedBox(height: 10),
      _ModalButton(
        label: 'Tomorrow · ${DateFormat('MMM d').format(tomorrow)}',
        filled: false,
        onTap: () => _postponeTo(tomorrow),
      ),
      const SizedBox(height: 8),
      _ModalButton(
        label: 'Next month · ${DateFormat('MMM d').format(nextMonth)}',
        filled: false,
        onTap: () => _postponeTo(nextMonth),
      ),
      const SizedBox(height: 8),
      _ModalButton(
        label: 'Pick a date…',
        filled: false,
        onTap: _pickDate,
      ),
      const SizedBox(height: 8),
      _ModalButton(
        label: 'Back',
        filled: false,
        muted: true,
        onTap: () => setState(() => _showPostponeOptions = false),
      ),
    ];
  }
}

class _ModalButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool muted;
  final VoidCallback onTap;

  const _ModalButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: AppColors.border),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.27),
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
              color: filled
                  ? Colors.white
                  : (muted ? AppColors.inkLight : AppColors.inkMid),
            ),
          ),
        ),
      ),
    );
  }
}
