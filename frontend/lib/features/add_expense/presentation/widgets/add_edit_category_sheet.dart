import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/categories_repository.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';

class AddEditCategorySheet extends ConsumerStatefulWidget {
  final Category? existing;

  const AddEditCategorySheet({super.key, this.existing});

  @override
  ConsumerState<AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _abbrCtrl;
  late String _selectedColorHex;
  bool _abbrAutoFilled = true;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelCtrl = TextEditingController(text: existing?.label ?? '');
    _abbrCtrl = TextEditingController(text: existing?.abbr ?? '');
    _selectedColorHex = existing?.color ?? AppColors.categoryPaletteHex.first;
    if (existing != null) _abbrAutoFilled = false;

    _labelCtrl.addListener(_onLabelChanged);
    _abbrCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _abbrCtrl.dispose();
    super.dispose();
  }

  void _onLabelChanged() {
    final label = _labelCtrl.text.trim();
    if (_abbrAutoFilled) {
      final auto = label.isEmpty
          ? ''
          : label.substring(0, min(3, label.length)).toUpperCase();
      _abbrCtrl.removeListener(() => setState(() {}));
      _abbrCtrl.text = auto;
      _abbrCtrl.addListener(() => setState(() {}));
    }
    setState(() {});
  }

  bool get _valid {
    if (_labelCtrl.text.trim().isEmpty) return false;
    if (_abbrCtrl.text.trim().isEmpty) return false;
    final existing = widget.existing;
    if (existing != null) {
      return _labelCtrl.text.trim() != existing.label ||
          _abbrCtrl.text.trim() != existing.abbr ||
          _selectedColorHex != existing.color;
    }
    return true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(categoriesRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.create(
          label: _labelCtrl.text.trim(),
          abbr: _abbrCtrl.text.trim(),
          colorHex: _selectedColorHex,
        );
      } else {
        await repo.update(
          id: existing.id,
          label: _labelCtrl.text.trim(),
          abbr: _abbrCtrl.text.trim(),
          colorHex: _selectedColorHex,
        );
      }
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on CategoriesApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null || existing.isSystem) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete category?'),
        content: Text(
          '"${existing.label}" will be removed. Existing transactions using it won\'t be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(categoriesRepositoryProvider).delete(existing.id);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on CategoriesApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not delete. Try again.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return EditSheetShell(
      title: isEdit ? 'Edit category' : 'New category',
      actionLabel: isEdit ? 'Save changes' : 'Add category',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldDecoration(
            child: TextField(
              controller: _labelCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
              decoration: _inputDecoration('Name', 'e.g. Groceries'),
            ),
          ),
          const SizedBox(height: 10),
          _fieldDecoration(
            child: TextField(
              controller: _abbrCtrl,
              maxLength: 3,
              onChanged: (_) => setState(() => _abbrAutoFilled = false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                _UpperCaseFormatter(),
              ],
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
              decoration: _inputDecoration('Abbreviation', 'e.g. GRC'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Color',
            style: AppTextStyles.labelStrong.copyWith(color: AppColors.inkMid),
          ),
          const SizedBox(height: 10),
          _ColorPalettePicker(
            selectedHex: _selectedColorHex,
            onSelected: (hex) => setState(() => _selectedColorHex = hex),
          ),
          if (isEdit && !widget.existing!.isSystem) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _deleting || _saving ? null : _delete,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _deleting ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.dangerLight,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.dangerLight,
                  ),
                  alignment: Alignment.center,
                  child: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.danger,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Delete category',
                              style: AppTextStyles.labelStrong.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldDecoration({required Widget child}) => child;

  InputDecoration _inputDecoration(String label, String hint) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.inkLight),
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkLight),
        filled: true,
        fillColor: AppColors.background,
        counterText: '',
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
      );
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _ColorPalettePicker extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onSelected;

  const _ColorPalettePicker({
    required this.selectedHex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: AppColors.categoryPalette.length,
      itemBuilder: (_, i) {
        final color = AppColors.categoryPalette[i];
        final hex = AppColors.categoryPaletteHex[i];
        final selected = hex == selectedHex;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(hex);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.ink : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
        );
      },
    );
  }
}
