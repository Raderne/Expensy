import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/profile_repository.dart';
import 'edit_sheet_shell.dart';

class EditNameSheet extends ConsumerStatefulWidget {
  final String initialName;
  const EditNameSheet({super.key, required this.initialName});

  @override
  ConsumerState<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<EditNameSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialName,
  );
  String _value = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = widget.initialName;
    _ctrl.addListener(() => setState(() => _value = _ctrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _dirtyValid {
    final trimmed = _value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= 80 &&
        trimmed != widget.initialName;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(profileRepositoryProvider)
          .updateName(_value.trim());
      await ref.read(authControllerProvider.notifier).updateUser(user);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
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
      title: 'Edit name',
      caption: 'How would you like to be greeted on the dashboard?',
      actionLabel: 'Save',
      actionEnabled: _dirtyValid,
      saving: _saving,
      error: _error,
      onAction: _save,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 80,
        style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 15),
        decoration: _decoration(label: 'Full name'),
      ),
    );
  }
}

InputDecoration _decoration({required String label}) {
  return InputDecoration(
    counterText: '',
    labelText: label,
    labelStyle: AppTextStyles.body,
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
