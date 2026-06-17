import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../contacts/data/contacts_repository.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/contacts_screen.dart';
import '../../domain/expense_split_draft.dart';

/// Reusable "Split this expense" card. Lets the user pick contacts and assign
/// each an owed amount (with a one-tap equal split), and shows a live preview of
/// the user's own remaining share. Emits the current draft list via [onChanged].
///
/// [amount] is the full positive expense total. The user's own share is the
/// remainder: amount − sum(owed).
class SplitEditor extends ConsumerStatefulWidget {
  final double amount;
  final List<ExpenseSplitDraft> initial;
  final ValueChanged<List<ExpenseSplitDraft>> onChanged;

  const SplitEditor({
    super.key,
    required this.amount,
    required this.onChanged,
    this.initial = const [],
  });

  @override
  ConsumerState<SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends ConsumerState<SplitEditor> {
  /// contactId → owed amount.
  late final Map<String, double> _owed = {
    for (final s in widget.initial) s.contactId: s.owedAmount,
  };

  void _emit() {
    widget.onChanged([
      for (final e in _owed.entries) ExpenseSplitDraft(contactId: e.key, owedAmount: e.value),
    ]);
  }

  void _toggle(Contact c) {
    setState(() {
      if (_owed.containsKey(c.id)) {
        _owed.remove(c.id);
      } else {
        _owed[c.id] = 0;
        _splitEqually();
        return; // _splitEqually emits
      }
    });
    _emit();
  }

  /// Divide the full amount evenly across the user + every selected contact,
  /// giving the user the rounding remainder.
  void _splitEqually() {
    final ids = _owed.keys.toList();
    if (ids.isEmpty) return;
    final parts = ids.length + 1; // +1 for the user
    final each = (widget.amount / parts);
    final rounded = (each * 100).floor() / 100;
    setState(() {
      for (final id in ids) {
        _owed[id] = rounded;
      }
    });
    _emit();
  }

  void _setAmount(String contactId, double value) {
    setState(() => _owed[contactId] = value);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsViewProvider);
    final contacts = contactsAsync.value ?? const <Contact>[];
    final byId = {for (final c in contacts) c.id: c};
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);

    final owedSum = _owed.values.fold(0.0, (a, b) => a + b);
    final yourShare = widget.amount - owedSum;
    final overSplit = widget.amount > 0 && owedSum >= widget.amount;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Split this expense', style: AppTextStyles.titleS),
              const Spacer(),
              if (_owed.isNotEmpty)
                GestureDetector(
                  onTap: _splitEqually,
                  child: Text(
                    'Split equally',
                    style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pick who shares this. Their part is tracked as owed to you.',
            style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
          ),
          const SizedBox(height: 12),

          if (contacts.isEmpty)
            _NoContactsHint()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in contacts)
                  _ContactChip(
                    contact: c,
                    selected: _owed.containsKey(c.id),
                    onTap: () => _toggle(c),
                  ),
              ],
            ),

          if (_owed.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final id in _owed.keys)
              if (byId[id] != null)
                _OwedRow(
                  contact: byId[id]!,
                  amount: _owed[id]!,
                  onChanged: (v) => _setAmount(id, v),
                ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: overSplit ? AppColors.dangerLight : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    overSplit ? Icons.warning_amber_rounded : Icons.person_rounded,
                    size: 18,
                    color: overSplit ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      overSplit
                          ? 'Others can\'t owe the whole bill — keep a share for yourself.'
                          : 'Your share',
                      style: AppTextStyles.label.copyWith(
                        color: overSplit ? AppColors.danger : AppColors.primaryInk,
                      ),
                    ),
                  ),
                  if (!overSplit)
                    Text(
                      money.format(yourShare),
                      style: AppTextStyles.labelStrong.copyWith(color: AppColors.primaryInk),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final Contact contact;
  final bool selected;
  final VoidCallback onTap;

  const _ContactChip({required this.contact, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContactAvatar(contact: contact, size: 24),
            const SizedBox(width: 6),
            Text(
              contact.name,
              style: AppTextStyles.label.copyWith(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwedRow extends StatefulWidget {
  final Contact contact;
  final double amount;
  final ValueChanged<double> onChanged;

  const _OwedRow({required this.contact, required this.amount, required this.onChanged});

  @override
  State<_OwedRow> createState() => _OwedRowState();
}

class _OwedRowState extends State<_OwedRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.amount));
  }

  @override
  void didUpdateWidget(covariant _OwedRow old) {
    super.didUpdateWidget(old);
    // Reflect programmatic changes (e.g. "split equally") without clobbering
    // an in-progress edit.
    final parsed = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (parsed != widget.amount && !_focused) {
      _ctrl.text = _fmt(widget.amount);
    }
  }

  bool _focused = false;

  static String _fmt(double v) => v == 0 ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

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
          ContactAvatar(contact: widget.contact, size: 32),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.contact.name, style: AppTextStyles.bodyStrong)),
          SizedBox(
            width: 96,
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: _ctrl,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyStrong,
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: 'owes ',
                  prefixStyle: AppTextStyles.mutedSmall,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.background,
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

class _NoContactsHint extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.group_add_outlined, size: 18, color: AppColors.inkMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add contacts in Profile → People to split with someone.',
              style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
            ),
          ),
        ],
      ),
    );
  }
}
