import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/data/categories_repository.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../analytics/application/analytics_controller.dart';
import '../../../dashboard/application/dashboard_controller.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../../recurring_confirmations/presentation/postponed_cycle_section.dart';
import '../../../shared/domain/recurring_share_draft.dart';
import '../../../shared/presentation/widgets/recurring_share_editor.dart';
import '../../../transactions/application/transactions_controller.dart';
import '../../application/recurring_expenses_controller.dart';
import '../../application/upcoming_bills_controller.dart';
import '../../data/recurring_expenses_repository.dart';
import '../../domain/recurring_expense.dart';
import 'frequency_picker.dart';

class EditRecurringExpenseSheet extends ConsumerStatefulWidget {
  final RecurringExpense? existing;

  const EditRecurringExpenseSheet({super.key, this.existing});

  @override
  ConsumerState<EditRecurringExpenseSheet> createState() =>
      _EditRecurringExpenseSheetState();
}

class _EditRecurringExpenseSheetState
    extends ConsumerState<EditRecurringExpenseSheet> {
  late final TextEditingController _labelCtrl = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late final TextEditingController _amountCtrl = TextEditingController(
    text: widget.existing != null && widget.existing!.amount > 0
        ? widget.existing!.amount.toStringAsFixed(
            widget.existing!.amount.truncateToDouble() ==
                    widget.existing!.amount
                ? 0
                : 2,
          )
        : '',
  );
  late final TextEditingController _intervalCtrl = TextEditingController(
    text: widget.existing?.intervalDays?.toString() ?? '',
  );

  String? _categoryId;
  late RecurrenceFrequency _frequency =
      widget.existing?.frequency ?? RecurrenceFrequency.monthly;
  late DateTime _anchorDate = widget.existing?.anchorDate ?? _today();
  late bool _isActive = widget.existing?.isActive ?? true;
  late List<RecurringShareDraft> _shares = widget.existing?.shares ?? const [];

  // Stable per-sheet key so a double-tap reuses it and the backend dedupes.
  final String _idempotencyKey = const Uuid().v4();

  bool _saving = false;
  String? _error;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId;
    _labelCtrl.addListener(() => setState(() {}));
    _amountCtrl.addListener(() => setState(() {}));
    _intervalCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final v = double.tryParse(_amountCtrl.text);
    if (v == null || v <= 0 || v > 1000000) return null;
    return v;
  }

  String get _trimmedLabel => _labelCtrl.text.trim();

  int? get _parsedInterval {
    final v = int.tryParse(_intervalCtrl.text);
    if (v == null || v < 1 || v > 365) return null;
    return v;
  }

  bool _sharesTouched = false;

  /// Others' percentages must stay under 100 so the user keeps a share.
  bool get _sharesValid =>
      _shares.fold(0.0, (sum, s) => sum + s.shareValue) < 100;

  bool get _valid {
    if (_parsedAmount == null) return false;
    if (_trimmedLabel.isEmpty || _trimmedLabel.length > 40) return false;
    if (_categoryId == null) return false;
    if (_frequency == RecurrenceFrequency.custom && _parsedInterval == null) {
      return false;
    }
    if (!_sharesValid) return false;

    final existing = widget.existing;
    if (existing == null) return true;
    // Edit: at least one field must differ.
    return _parsedAmount != existing.amount ||
        _trimmedLabel != existing.label ||
        _categoryId != existing.categoryId ||
        _frequency != existing.frequency ||
        (_frequency == RecurrenceFrequency.custom &&
            _parsedInterval != existing.intervalDays) ||
        !_isSameDay(_anchorDate, existing.anchorDate) ||
        _isActive != existing.isActive ||
        _sharesTouched;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickAnchorDate() async {
    final now = _today();
    final initial = _anchorDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => _anchorDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _save() async {
    final amount = _parsedAmount;
    if (amount == null || _trimmedLabel.isEmpty || _categoryId == null) return;
    if (_frequency == RecurrenceFrequency.custom && _parsedInterval == null) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(recurringExpensesRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(
          label: _trimmedLabel,
          amount: amount,
          categoryId: _categoryId,
          frequency: _frequency,
          intervalDays: _frequency == RecurrenceFrequency.custom
              ? _parsedInterval
              : null,
          anchorDate: _anchorDate,
          shares: _shares,
          idempotencyKey: _idempotencyKey,
        );
      } else {
        await repo.update(
          id: widget.existing!.id,
          label: _trimmedLabel,
          amount: amount,
          categoryId: _categoryId,
          frequency: _frequency,
          intervalDays: _frequency == RecurrenceFrequency.custom
              ? _parsedInterval
              : null,
          clearIntervalDays: _frequency != RecurrenceFrequency.custom,
          anchorDate: _anchorDate,
          isActive: _isActive,
          shares: _sharesTouched ? _shares : null,
        );
      }
      _invalidateDownstream();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on RecurringExpensesApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidateDownstream() {
    ref.invalidate(recurringExpensesControllerProvider);
    ref.invalidate(upcomingBillsControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(analyticsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final categoriesAsync = ref.watch(categoriesViewProvider);

    return EditSheetShell(
      title: isEdit ? 'Edit subscription' : 'Add recurring expense',
      caption: isEdit
          ? 'Update the cadence or pause it to stop new charges.'
          : 'Repeats automatically — appears in your transactions on each due date.',
      actionLabel: isEdit ? 'Save changes' : 'Add',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _labelCtrl,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            style: AppTextStyles.body.copyWith(color: AppColors.ink),
            decoration: _fieldDecoration(hint: 'YouTube Premium'),
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
            decoration: _fieldDecoration(hint: '9.99', prefix: '\$'),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Frequency'),
          const SizedBox(height: 6),
          FrequencyPicker(
            value: _frequency,
            onChanged: (f) {
              setState(() {
                _frequency = f;
                if (f != RecurrenceFrequency.custom) _intervalCtrl.clear();
              });
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _frequency == RecurrenceFrequency.custom
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _intervalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.body.copyWith(color: AppColors.ink),
                      decoration: _fieldDecoration(
                        hint: '45',
                        prefix: 'Every ',
                        suffix: ' days',
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Category'),
          const SizedBox(height: 6),
          categoriesAsync.when(
            loading: () => const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (_, _) => Text(
              'Could not load categories',
              style: AppTextStyles.label.copyWith(color: AppColors.danger),
            ),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              _ensureCategoryDefault(categories);
              return _CategoryRow(
                categories: categories,
                selectedId: _categoryId,
                onSelect: (c) {
                  HapticFeedback.selectionClick();
                  setState(() => _categoryId = c.id);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Starts on'),
          const SizedBox(height: 6),
          _AnchorRow(date: _anchorDate, onTap: _pickAnchorDate),
          const SizedBox(height: 16),
          const _SectionLabel('Shared with'),
          const SizedBox(height: 6),
          RecurringShareEditor(
            initial: _shares,
            onChanged: (s) => setState(() {
              _shares = s;
              _sharesTouched = true;
            }),
          ),
          if (isEdit) ...[
            const SizedBox(height: 16),
            _ActiveToggle(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
          if (isEdit && widget.existing!.postponed != null)
            PostponedCycleSection(
              initial: widget.existing!.postponed!,
              onChanged: () =>
                  ref.invalidate(recurringExpensesControllerProvider),
            ),
        ],
      ),
    );
  }

  void _ensureCategoryDefault(List<Category> categories) {
    if (_categoryId != null && categories.any((c) => c.id == _categoryId)) {
      return;
    }
    // Default to subscriptions, fall back to first category.
    final subs = categories.firstWhere(
      (c) => c.key == 'subscriptions',
      orElse: () => categories.first,
    );
    // Schedule after the build to avoid a setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _categoryId = subs.id);
    });
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? prefix,
    String? suffix,
    bool counter = false,
  }) {
    return InputDecoration(
      prefixText: prefix,
      suffixText: suffix,
      prefixStyle: prefix != null
          ? AppTextStyles.body.copyWith(
              color: AppColors.inkMid,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )
          : null,
      suffixStyle: AppTextStyles.body.copyWith(color: AppColors.inkMid),
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkLight),
      filled: true,
      fillColor: AppColors.background,
      counterText: counter ? null : '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.muted.copyWith(
        fontSize: 12,
        color: AppColors.inkMid,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const _CategoryRow({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Show non-income categories — income never makes sense for an expense.
    final visible = categories.where((c) => c.key != 'income').toList();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = visible[i];
          final selected = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? c.colorValue : c.bgTintValue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? c.colorValue : c.bgTintValue,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                c.label,
                style: AppTextStyles.labelStrong.copyWith(
                  color: selected ? Colors.white : c.colorValue,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _AnchorRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d, yyyy').format(date);
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.inkMid,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(fmt, style: AppTextStyles.bodyStrong)),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.inkLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ActiveToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.autorenew_rounded, size: 18, color: AppColors.inkMid),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ? 'Active' : 'Paused',
                  style: AppTextStyles.bodyStrong,
                ),
                Text(
                  value
                      ? 'Posts automatically on each due date.'
                      : 'No new charges will be posted.',
                  style: AppTextStyles.muted.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
