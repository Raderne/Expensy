import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../contacts/data/contacts_repository.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/contacts_screen.dart';
import '../../domain/recurring_share_draft.dart';

/// "Split this bill" editor for recurring rules. Percentage-based (robust when
/// the bill amount changes), with a one-tap equal split and a live preview of
/// the user's own share. Emits [RecurringShareDraft]s of type PERCENT.
class RecurringShareEditor extends ConsumerStatefulWidget {
  final List<RecurringShareDraft> initial;
  final ValueChanged<List<RecurringShareDraft>> onChanged;

  const RecurringShareEditor({super.key, required this.onChanged, this.initial = const []});

  @override
  ConsumerState<RecurringShareEditor> createState() => _RecurringShareEditorState();
}

class _RecurringShareEditorState extends ConsumerState<RecurringShareEditor> {
  /// contactId → percent (0..100).
  late final Map<String, double> _pct = {
    for (final s in widget.initial) s.contactId: s.shareValue,
  };

  void _emit() {
    widget.onChanged([
      for (final e in _pct.entries)
        RecurringShareDraft(
          contactId: e.key,
          shareType: ShareType.percent,
          shareValue: e.value,
        ),
    ]);
  }

  void _toggle(Contact c) {
    if (_pct.containsKey(c.id)) {
      setState(() => _pct.remove(c.id));
      _emit();
    } else {
      _pct[c.id] = 0;
      _splitEqually();
    }
  }

  void _splitEqually() {
    if (_pct.isEmpty) return;
    final parts = _pct.length + 1; // +1 for the user
    final each = (100 / parts);
    final rounded = (each * 10).round() / 10;
    setState(() {
      for (final id in _pct.keys) {
        _pct[id] = rounded;
      }
    });
    _emit();
  }

  void _set(String id, double v) {
    setState(() => _pct[id] = v.clamp(0, 100));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsViewProvider).value ?? const <Contact>[];
    final byId = {for (final c in contacts) c.id: c};
    final owedPct = _pct.values.fold(0.0, (a, b) => a + b);
    final yourPct = (100 - owedPct).clamp(0, 100).toDouble();
    final over = owedPct >= 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Split this bill', style: AppTextStyles.titleS),
              const Spacer(),
              if (_pct.isNotEmpty)
                GestureDetector(
                  onTap: _splitEqually,
                  child: Text(
                    'Equally',
                    style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each charge will track the part others owe you.',
            style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty)
            Text(
              'Add contacts in Profile → People to split this bill.',
              style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in contacts)
                  _Chip(contact: c, selected: _pct.containsKey(c.id), onTap: () => _toggle(c)),
              ],
            ),
          if (_pct.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final id in _pct.keys)
              if (byId[id] != null)
                _PercentRow(
                  contact: byId[id]!,
                  percent: _pct[id]!,
                  onChanged: (v) => _set(id, v),
                ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  over ? Icons.warning_amber_rounded : Icons.person_rounded,
                  size: 16,
                  color: over ? AppColors.danger : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    over ? 'Keep a share for yourself (under 100%).' : 'Your share',
                    style: AppTextStyles.label.copyWith(
                      color: over ? AppColors.danger : AppColors.inkMid,
                    ),
                  ),
                ),
                if (!over)
                  Text(
                    '${yourPct.toStringAsFixed(yourPct % 1 == 0 ? 0 : 1)}%',
                    style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Contact contact;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.contact, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContactAvatar(contact: contact, size: 22),
            const SizedBox(width: 6),
            Text(
              contact.name,
              style: AppTextStyles.label.copyWith(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentRow extends StatefulWidget {
  final Contact contact;
  final double percent;
  final ValueChanged<double> onChanged;
  const _PercentRow({required this.contact, required this.percent, required this.onChanged});

  @override
  State<_PercentRow> createState() => _PercentRowState();
}

class _PercentRowState extends State<_PercentRow> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _fmt(widget.percent));
  bool _focused = false;

  static String _fmt(double v) =>
      v == 0 ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1));

  @override
  void didUpdateWidget(covariant _PercentRow old) {
    super.didUpdateWidget(old);
    final parsed = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (parsed != widget.percent && !_focused) _ctrl.text = _fmt(widget.percent);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ContactAvatar(contact: widget.contact, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.contact.name, style: AppTextStyles.bodyStrong)),
          SizedBox(
            width: 78,
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: _ctrl,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                style: AppTextStyles.bodyStrong,
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: '%',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => widget.onChanged(double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
