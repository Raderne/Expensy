import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/categories_repository.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../application/transactions_controller.dart';

/// Modal bottom sheet that stages filter changes locally and only applies them
/// when the user taps "Show Results". Drag-to-dismiss discards the staged
/// changes — same UX as a typical iOS/Android filter UI.
Future<void> showTransactionsFiltersSheet(
  BuildContext context, {
  required TransactionFilters initial,
  required ValueChanged<TransactionFilters> onApply,
}) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (_) => _FiltersSheet(initial: initial, onApply: onApply),
  );
}

class _FiltersSheet extends ConsumerStatefulWidget {
  final TransactionFilters initial;
  final ValueChanged<TransactionFilters> onApply;

  const _FiltersSheet({required this.initial, required this.onApply});

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late TransactionFilters _staged = widget.initial;

  bool get _dirty => _staged != widget.initial;

  void _setType(TxTypeFilter type) {
    HapticFeedback.selectionClick();
    setState(
      () => _staged = _staged.copyWith(type: type, clearType: type == null),
    );
  }

  void _setCategory(String? id) {
    HapticFeedback.selectionClick();
    setState(
      () => _staged = _staged.copyWith(
        categoryId: id,
        clearCategoryId: id == null,
      ),
    );
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() => _staged = TransactionFilters.none);
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    widget.onApply(_staged);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesViewProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.scrim,
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _DragHandle(),
              const SizedBox(height: 14),
              _Header(showReset: _staged.isActive, onReset: _reset),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(text: 'TYPE'),
                      const SizedBox(height: 10),
                      _TypeSegment(selected: _staged.type, onSelect: _setType),
                      const SizedBox(height: 22),
                      const _SectionLabel(text: 'CATEGORY'),
                      const SizedBox(height: 10),
                      categoriesAsync.when(
                        loading: () => const _CategoriesSkeleton(),
                        error: (_, _) => Text(
                          'Could not load categories',
                          style: AppTextStyles.body,
                        ),
                        data: (cats) => _CategoryChips(
                          categories: cats,
                          selectedId: _staged.categoryId,
                          onSelect: _setCategory,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: _ApplyButton(enabled: _dirty, onTap: _apply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.inkFaint,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool showReset;
  final VoidCallback onReset;

  const _Header({required this.showReset, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('Filter Transactions', style: AppTextStyles.titleM),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: showReset
                ? TextButton(
                    key: const ValueKey('reset'),
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Reset',
                      style: AppTextStyles.labelStrong.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.muted.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppColors.inkMid,
      ),
    );
  }
}

// ─── Type segmented control ──────────────────────────────────────────────────

class _TypeSegment extends StatelessWidget {
  final TxTypeFilter selected;
  final ValueChanged<TxTypeFilter> onSelect;

  const _TypeSegment({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment('All', null),
          _segment('Income', 'income'),
          _segment('Expense', 'expense'),
        ],
      ),
    );
  }

  Widget _segment(String label, TxTypeFilter value) {
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? null : () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x14000C22),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelStrong.copyWith(
              fontSize: 13,
              color: active ? AppColors.ink : AppColors.inkMid,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category chips ──────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'All',
          selected: selectedId == null,
          color: AppColors.primary,
          bgTint: AppColors.primaryLight,
          onTap: () => onSelect(null),
        ),
        ...categories.map(
          (c) => _Chip(
            label: c.label,
            selected: c.id == selectedId,
            color: c.colorValue,
            bgTint: c.bgTintValue,
            onTap: () => onSelect(c.id),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color bgTint;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.bgTint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : bgTint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelStrong.copyWith(
            fontSize: 13,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        6,
        (i) => Container(
          width: 70 + (i.isEven ? 12.0 : 0.0),
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.inkFaint,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

// ─── Apply button ────────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ApplyButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.inkFaint,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.27),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          'Show Results',
          style: AppTextStyles.labelStrong.copyWith(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
