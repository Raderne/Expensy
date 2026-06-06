import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../../transactions/application/transactions_controller.dart';
import '../../data/income_repository.dart';

class AddSideIncomeSheet extends ConsumerStatefulWidget {
  const AddSideIncomeSheet({super.key});

  @override
  ConsumerState<AddSideIncomeSheet> createState() => _AddSideIncomeSheetState();
}

class _AddSideIncomeSheetState extends ConsumerState<AddSideIncomeSheet> {
  late final TextEditingController _amountCtrl = TextEditingController();
  late final TextEditingController _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  // Stable per-sheet key so a double-tap reuses it and the backend dedupes.
  final String _idempotencyKey = const Uuid().v4();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double? get _parsed {
    final v = double.tryParse(_amountCtrl.text);
    if (v == null || v <= 0 || v > 1000000) return null;
    return v;
  }

  bool get _valid => _parsed != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = _parsed;
    if (amount == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final note = _noteCtrl.text.trim();
      await ref
          .read(incomeRepositoryProvider)
          .createSideIncome(
            amount: amount,
            note: note.isEmpty ? null : note,
            occurredAt: DateTime(_date.year, _date.month, _date.day),
            idempotencyKey: _idempotencyKey,
          );
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
    final dateLabel =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return EditSheetShell(
      title: 'Add side income',
      caption: 'One-off income from freelance, gifts, or other sources.',
      actionLabel: 'Add income',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountCtrl,
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
              hintText: '500',
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
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.2,
                ),
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
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Note (optional)',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkLight),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.2,
                ),
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
          const SizedBox(height: 12),
          Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.inkMid,
                    ),
                    const SizedBox(width: 10),
                    Text(dateLabel, style: AppTextStyles.bodyStrong),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
