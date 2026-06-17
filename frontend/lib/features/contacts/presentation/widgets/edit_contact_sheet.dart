import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';

/// Add or edit a contact: name + an avatar colour from the brand palette.
/// Returns true on success so the caller can show a confirmation.
class EditContactSheet extends ConsumerStatefulWidget {
  final Contact? existing;
  const EditContactSheet({super.key, this.existing});

  @override
  ConsumerState<EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends ConsumerState<EditContactSheet> {
  late final TextEditingController _name;
  late String _colorHex;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _colorHex = widget.existing?.color ?? AppColors.categoryPaletteHex.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(contactsRepositoryProvider);
    final name = _name.text.trim();
    try {
      if (widget.existing == null) {
        await repo.create(name: name, color: _colorHex);
      } else {
        await repo.update(id: widget.existing!.id, name: name, color: _colorHex);
      }
      ref.invalidate(contactsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Could not save. It will sync when back online.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditSheetShell(
      title: widget.existing == null ? 'Add contact' : 'Edit contact',
      caption: 'Someone you split expenses with.',
      actionLabel: widget.existing == null ? 'Add contact' : 'Save',
      actionEnabled: _valid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.bodyStrong,
            decoration: InputDecoration(
              hintText: 'Name (e.g. Brother)',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Colour', style: AppTextStyles.label.copyWith(color: AppColors.inkMid)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < AppColors.categoryPalette.length; i++)
                _ColorDot(
                  color: AppColors.categoryPalette[i],
                  selected: AppColors.categoryPaletteHex[i] == _colorHex,
                  onTap: () => setState(() => _colorHex = AppColors.categoryPaletteHex[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: AppColors.ink, width: 2.5) : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
