import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../data/profile_repository.dart';
import 'edit_sheet_shell.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  final double initialAmount;
  const EditBudgetSheet({super.key, required this.initialAmount});

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialAmount > 0
        ? widget.initialAmount.toStringAsFixed(0)
        : '',
  );
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

  bool get _valid => _parsed != null && _parsed != widget.initialAmount;

  Future<void> _save() async {
    final amount = _parsed;
    if (amount == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateBudget(amount);
      ref.invalidate(dashboardControllerProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on ProfileApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditSheetShell(
      title: 'Monthly budget',
      caption:
          'Cap how much you plan to spend each month. Used on the dashboard progress bar.',
      actionLabel: 'Save budget',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
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
          hintText: '2,500',
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.inkLight,
            fontSize: 18,
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.2),
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
