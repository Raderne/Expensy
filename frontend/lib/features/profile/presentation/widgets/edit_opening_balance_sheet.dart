import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../data/profile_repository.dart';
import 'edit_sheet_shell.dart';

/// Sets the user's starting bank balance. Unlike the budget sheet, negative
/// (overdraft) and zero (cleared) values are valid — it's a flat offset the
/// dashboard adds on top of the transaction ledger.
class EditOpeningBalanceSheet extends ConsumerStatefulWidget {
  final double initialAmount;
  const EditOpeningBalanceSheet({super.key, required this.initialAmount});

  @override
  ConsumerState<EditOpeningBalanceSheet> createState() =>
      _EditOpeningBalanceSheetState();
}

class _EditOpeningBalanceSheetState
    extends ConsumerState<EditOpeningBalanceSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialAmount != 0
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
    if (_ctrl.text.trim().isEmpty) return null;
    final v = double.tryParse(_ctrl.text);
    if (v == null || v.abs() > 1000000000) return null;
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
      final saved = await ref
          .read(profileRepositoryProvider)
          .updateOpeningBalance(amount);
      // Keep the cached user (and this sheet's seed) in sync with the server.
      final current = switch (ref.read(authControllerProvider).value) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      };
      if (current != null) {
        await ref
            .read(authControllerProvider.notifier)
            .updateUser(current.copyWith(openingBalance: saved));
      }
      // Balance shown on the dashboard is derived server-side; refetch it.
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
      title: 'Opening balance',
      caption:
          'The money you already hold (e.g. your bank balance). Added on top of '
          'everything you track. Use a negative value for an overdraft.',
      actionLabel: 'Save balance',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.-]'))],
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
          hintText: '100,000',
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
