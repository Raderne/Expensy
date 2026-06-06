import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../../transactions/application/transactions_controller.dart';
import '../../application/income_controller.dart';
import '../../data/income_repository.dart';
import '../../domain/recurring_income.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';

class EditRecurringIncomeSheet extends ConsumerStatefulWidget {
  final RecurringIncome? existing;

  const EditRecurringIncomeSheet({super.key, this.existing});

  @override
  ConsumerState<EditRecurringIncomeSheet> createState() =>
      _EditRecurringIncomeSheetState();
}

class _EditRecurringIncomeSheetState extends ConsumerState<EditRecurringIncomeSheet> {
  late final TextEditingController _labelCtrl = TextEditingController(
    text: widget.existing?.label ?? 'Main job',
  );
  late final TextEditingController _amountCtrl = TextEditingController(
    text: widget.existing != null && widget.existing!.amount > 0
        ? widget.existing!.amount.toStringAsFixed(0)
        : '',
  );
  late int _dayOfMonth = widget.existing?.dayOfMonth ?? 1;

  // One idempotency key for this sheet's lifetime, so a double-tap (or a retry
  // while the request is slow) reuses the same key and the backend dedupes it.
  final String _idempotencyKey = const Uuid().v4();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
    _labelCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final v = double.tryParse(_amountCtrl.text);
    if (v == null || v <= 0 || v > 1000000) return null;
    return v;
  }

  String get _trimmedLabel => _labelCtrl.text.trim();

  bool get _valid =>
      _parsedAmount != null &&
      _trimmedLabel.isNotEmpty &&
      _trimmedLabel.length <= 40 &&
      (widget.existing == null ||
          _parsedAmount != widget.existing!.amount ||
          _dayOfMonth != widget.existing!.dayOfMonth ||
          _trimmedLabel != widget.existing!.label);

  Future<void> _save() async {
    final amount = _parsedAmount;
    if (amount == null || _trimmedLabel.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(incomeRepositoryProvider);
      if (widget.existing == null) {
        await repo.createRecurring(
          label: _trimmedLabel,
          amount: amount,
          dayOfMonth: _dayOfMonth,
          idempotencyKey: _idempotencyKey,
        );
      } else {
        await repo.updateRecurring(
          id: widget.existing!.id,
          label: _trimmedLabel,
          amount: amount,
          dayOfMonth: _dayOfMonth,
        );
      }
      ref.invalidate(incomeControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(transactionsControllerProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on IncomeApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return EditSheetShell(
      title: isEdit ? 'Edit income source' : 'Add income source',
      caption: 'Income is added automatically on this day each month.',
      actionLabel: isEdit ? 'Save changes' : 'Add source',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _labelCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body.copyWith(color: AppColors.ink),
            decoration: _fieldDecoration(hint: 'Main job'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            autofocus: !isEdit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: AppTextStyles.body.copyWith(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: _fieldDecoration(hint: '5,200', prefix: '\$'),
          ),
          const SizedBox(height: 12),
          Text(
            'Paid on day',
            style: AppTextStyles.muted.copyWith(fontSize: 12, color: AppColors.inkMid),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _dayOfMonth,
                isExpanded: true,
                items: List.generate(
                  28,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Day ${i + 1}', style: AppTextStyles.bodyStrong),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _dayOfMonth = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, String? prefix}) {
    return InputDecoration(
      prefixText: prefix,
      prefixStyle: prefix != null
          ? AppTextStyles.body.copyWith(
              color: AppColors.inkMid,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )
          : null,
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkLight),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}
