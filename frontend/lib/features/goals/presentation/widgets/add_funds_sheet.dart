import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../application/goals_controller.dart';
import '../../data/goals_repository.dart';
import '../../domain/goal.dart';

class AddFundsSheet extends ConsumerStatefulWidget {
  final Goal goal;

  const AddFundsSheet({super.key, required this.goal});

  @override
  ConsumerState<AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends ConsumerState<AddFundsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final String _idempotencyKey = const Uuid().v4();
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

  double? get _parsed {
    final v = double.tryParse(_ctrl.text);
    if (v == null || v <= 0 || v > 1000000) return null;
    return v;
  }

  Future<void> _save() async {
    final amount = _parsed;
    if (amount == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(goalsRepositoryProvider).addFunds(
        id: widget.goal.id,
        amount: amount,
        idempotencyKey: _idempotencyKey,
      );
      ref.invalidate(goalsControllerProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on GoalsApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final g = widget.goal;
    return EditSheetShell(
      title: 'Add funds',
      caption:
          '${g.name} · ${money.format(g.savedAmount)} of ${money.format(g.targetAmount)} saved',
      actionLabel: 'Add funds',
      actionEnabled: _parsed != null,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
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
          hintText: '500',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkLight),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
