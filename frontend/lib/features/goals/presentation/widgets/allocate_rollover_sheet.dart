import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../application/goals_controller.dart';
import '../../application/rollovers_controller.dart';
import '../../data/goals_repository.dart' show GoalsApiException;
import '../../data/rollovers_repository.dart';
import '../../domain/budget_rollover.dart';
import '../../domain/goal.dart';

/// Bottom sheet to move a closed month's leftover budget into a savings goal:
/// pick a goal, choose an amount (defaults to the full remaining, capped at it).
class AllocateRolloverSheet extends ConsumerStatefulWidget {
  final BudgetRollover rollover;

  const AllocateRolloverSheet({super.key, required this.rollover});

  @override
  ConsumerState<AllocateRolloverSheet> createState() =>
      _AllocateRolloverSheetState();
}

class _AllocateRolloverSheetState extends ConsumerState<AllocateRolloverSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: _fmtInput(widget.rollover.remaining),
  );
  final String _idempotencyKey = const Uuid().v4();
  String? _goalId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _fmtInput(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? get _parsed {
    final v = double.tryParse(_ctrl.text);
    if (v == null || v <= 0 || v > widget.rollover.remaining + 0.001) {
      return null;
    }
    return v;
  }

  String? _selectedGoalId(List<Goal> goals) =>
      _goalId ?? (goals.isNotEmpty ? goals.first.id : null);

  Future<void> _save() async {
    final goals = ref.read(goalsControllerProvider).value ?? const <Goal>[];
    final goalId = _selectedGoalId(goals);
    final amount = _parsed;
    if (goalId == null || amount == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(rolloversRepositoryProvider).allocate(
        month: widget.rollover.month,
        goalId: goalId,
        amount: amount,
        idempotencyKey: _idempotencyKey,
      );
      ref.invalidate(goalsControllerProvider);
      ref.invalidate(rolloversControllerProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on GoalsApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not allocate. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final monthLabel = DateFormat('MMMM yyyy').format(widget.rollover.monthDate);
    final goals = ref.watch(goalsControllerProvider).value ?? const <Goal>[];
    final selected = _selectedGoalId(goals);
    final canAllocate = selected != null && _parsed != null;

    return EditSheetShell(
      title: 'Allocate leftover',
      caption:
          '${money.format(widget.rollover.remaining)} left from $monthLabel',
      actionLabel: 'Add to goal',
      actionEnabled: canAllocate,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (goals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Create a savings goal first, then you can move this leftover into it.',
                style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
              ),
            )
          else ...[
            Text(
              'GOAL',
              style: AppTextStyles.muted.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.inkMid,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in goals)
                  _GoalChip(
                    goal: g,
                    selected: g.id == selected,
                    onTap: () => setState(() => _goalId = g.id),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'AMOUNT',
              style: AppTextStyles.muted.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.inkMid,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: AppTextStyles.body.copyWith(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '\$',
                prefixStyle: AppTextStyles.body.copyWith(
                  color: AppColors.inkMid,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                hintText: _fmtInput(widget.rollover.remaining),
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.inkLight,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final Goal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = goal.colorValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              goal.iconData,
              size: 15,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              goal.name,
              style: AppTextStyles.label.copyWith(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
