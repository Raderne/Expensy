import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../../transactions/application/transactions_controller.dart';
import '../../application/owed_controller.dart';
import '../../data/shared_repository.dart';
import '../../domain/owed_overview.dart';

/// Records a (partial or full) repayment toward a split. Defaults to the full
/// remaining balance; the user can lower it for a partial payment.
class SettleSheet extends ConsumerStatefulWidget {
  final OwedSplit split;
  final String contactName;
  const SettleSheet({super.key, required this.split, required this.contactName});

  @override
  ConsumerState<SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends ConsumerState<SettleSheet> {
  late final TextEditingController _amount;
  final String _idempotencyKey = const Uuid().v4();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.split.remaining.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
  bool get _valid => _value > 0 && _value <= widget.split.remaining + 0.001;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(sharedRepositoryProvider).recordReimbursement(
            splitId: widget.split.splitId,
            amount: _value,
            idempotencyKey: _idempotencyKey,
          );
      // Refresh dependent surfaces: the split's remaining drops and the inflow
      // appears in the ledger / balance.
      ref.invalidate(owedControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(transactionsControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      setState(() => _error = "Couldn't record repayment. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    return EditSheetShell(
      title: 'Record repayment',
      caption: '${widget.contactName} · ${widget.split.label}',
      actionLabel: 'Mark as paid',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('Still owed', style: AppTextStyles.label.copyWith(color: AppColors.primaryInk)),
                const Spacer(),
                Text(
                  money.format(widget.split.remaining),
                  style: AppTextStyles.labelStrong.copyWith(color: AppColors.primaryInk),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Amount received', style: AppTextStyles.label.copyWith(color: AppColors.inkMid)),
          const SizedBox(height: 6),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.titleM,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
