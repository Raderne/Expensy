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
import '../../domain/goal_icons.dart';

class EditGoalSheet extends ConsumerStatefulWidget {
  final Goal? existing;

  const EditGoalSheet({super.key, this.existing});

  @override
  ConsumerState<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<EditGoalSheet> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _targetCtrl = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.targetAmount.toStringAsFixed(0)
        : '',
  );
  late final TextEditingController _savedCtrl = TextEditingController(
    text: widget.existing != null && widget.existing!.savedAmount > 0
        ? widget.existing!.savedAmount.toStringAsFixed(0)
        : '',
  );

  late String _icon = widget.existing?.icon ?? kDefaultGoalIcon;
  late String _colorHex = widget.existing?.color ?? AppColors.categoryPaletteHex.first;
  late DateTime? _targetDate = widget.existing?.targetDate;

  final String _idempotencyKey = const Uuid().v4();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
    _targetCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _savedCtrl.dispose();
    super.dispose();
  }

  String get _trimmedName => _nameCtrl.text.trim();

  double? get _parsedTarget {
    final v = double.tryParse(_targetCtrl.text);
    if (v == null || v <= 0 || v > 1000000) return null;
    return v;
  }

  double get _parsedSaved {
    final v = double.tryParse(_savedCtrl.text);
    if (v == null || v < 0 || v > 1000000) return 0;
    return v;
  }

  bool get _valid =>
      _trimmedName.isNotEmpty &&
      _trimmedName.length <= 40 &&
      _parsedTarget != null;

  Color get _color =>
      Goal(
        id: '',
        name: '',
        icon: _icon,
        color: _colorHex,
        targetAmount: 1,
        savedAmount: 0,
      ).colorValue;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year, now.month + 1, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    final target = _parsedTarget;
    if (target == null || _trimmedName.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(goalsRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(
          name: _trimmedName,
          icon: _icon,
          color: _colorHex,
          targetAmount: target,
          savedAmount: _parsedSaved,
          targetDate: _targetDate,
          idempotencyKey: _idempotencyKey,
        );
      } else {
        await repo.update(
          id: widget.existing!.id,
          name: _trimmedName,
          icon: _icon,
          color: _colorHex,
          targetAmount: target,
          savedAmount: _parsedSaved,
          targetDate: _targetDate,
        );
      }
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
    final isEdit = widget.existing != null;
    return EditSheetShell(
      title: isEdit ? 'Edit goal' : 'New goal',
      caption: 'Set what you’re saving for and how much you need.',
      actionLabel: isEdit ? 'Save changes' : 'Create goal',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body.copyWith(color: AppColors.ink),
            decoration: _decoration(hint: 'New car'),
          ),
          const SizedBox(height: 16),
          _label('Icon'),
          const SizedBox(height: 8),
          _IconPicker(
            selected: _icon,
            color: _color,
            onSelect: (key) => setState(() => _icon = key),
          ),
          const SizedBox(height: 16),
          _label('Color'),
          const SizedBox(height: 8),
          _ColorPicker(
            selectedHex: _colorHex,
            onSelect: (hex) => setState(() => _colorHex = hex),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Target'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      style: _amountStyle,
                      decoration: _decoration(hint: '25,000', prefix: '\$'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Saved'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _savedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      style: _amountStyle,
                      decoration: _decoration(hint: '0', prefix: '\$'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Target date (optional)'),
          const SizedBox(height: 6),
          _DateField(
            date: _targetDate,
            onTap: _pickDate,
            onClear: () => setState(() => _targetDate = null),
          ),
        ],
      ),
    );
  }

  TextStyle get _amountStyle => AppTextStyles.body.copyWith(
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.muted.copyWith(fontSize: 12, color: AppColors.inkMid),
  );

  InputDecoration _decoration({required String hint, String? prefix}) {
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

class _IconPicker extends StatelessWidget {
  final String selected;
  final Color color;
  final ValueChanged<String> onSelect;

  const _IconPicker({
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in kGoalIcons.entries)
          _Swatch(
            selected: entry.key == selected,
            color: color,
            onTap: () => onSelect(entry.key),
            child: Icon(
              entry.value,
              size: 20,
              color: entry.key == selected ? Colors.white : AppColors.inkMid,
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onSelect;

  const _ColorPicker({required this.selectedHex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final hexes = AppColors.categoryPaletteHex;
    final colors = AppColors.categoryPalette;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < hexes.length; i++)
          GestureDetector(
            onTap: () => onSelect(hexes[i]),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: hexes[i] == selectedHex
                      ? AppColors.ink
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: hexes[i] == selectedHex
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _Swatch({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 18,
              color: hasDate ? AppColors.primary : AppColors.inkLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('MMMM yyyy').format(date!)
                    : 'No deadline',
                style: AppTextStyles.body.copyWith(
                  color: hasDate ? AppColors.ink : AppColors.inkLight,
                ),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.inkLight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
