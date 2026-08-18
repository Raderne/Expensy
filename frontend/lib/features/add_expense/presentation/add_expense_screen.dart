import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/categories_repository.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/expanded_add_pane.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/system_overlays.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../dashboard/domain/recent_transaction.dart';
import '../application/add_expense_controller.dart';
import '../domain/amount_input.dart';
import 'widgets/amount_display.dart';
import 'widgets/category_grid.dart';
import 'widgets/numpad.dart';
import 'widgets/split_sheet.dart';
import 'widgets/success_popup.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  /// When true, renders as a shell companion pane (no route pop on close).
  final bool embedded;

  /// Called when the user dismisses the embedded pane. Ignored when not
  /// [embedded].
  final VoidCallback? onClose;

  const AddExpenseScreen({super.key, this.embedded = false, this.onClose});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  // Guards against opening the success popup more than once per save.
  bool _popupOpen = false;
  bool _redirectScheduled = false;

  Future<void> _onSaved(RecentTransaction tx) async {
    if (_popupOpen) return;
    _popupOpen = true;
    // Medium-impact haptic exactly once on save success.
    HapticFeedback.mediumImpact();

    final action = await showSuccessPopup(context, transaction: tx);
    _popupOpen = false;
    if (!mounted) return;

    // Clear the form either way; if the user didn't pick "Add Another",
    // close the modal / embedded pane back to wherever it was launched from.
    ref.read(addExpenseControllerProvider.notifier).reset();
    if (action != SuccessAction.addAnother) {
      _dismiss();
    }
  }

  void _dismiss() {
    if (widget.embedded) {
      widget.onClose?.call();
      return;
    }
    if (context.canPop()) context.pop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fold/unfold or widget deep-link on an expanded window: don't cover the
    // two-pane shell with the fullscreen modal — hand off to the companion pane.
    if (widget.embedded || _redirectScheduled) return;
    if (!useTwoPane(context)) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(expandedAddPaneProvider.notifier).open();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addExpenseControllerProvider);
    final controller = ref.read(addExpenseControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesViewProvider);

    ref.listen<AddExpenseState>(addExpenseControllerProvider, (prev, next) {
      if (prev?.saved == null && next.saved != null) {
        _onSaved(next.saved!);
      }
    });

    final amount = AmountInput.parse(state.amount);

    final body = SafeArea(
      // Embedded pane already sits inside the shell SafeArea; keep bottom
      // clear of the translucent nav via MediaQuery padding from Scaffold.
      top: !widget.embedded,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _Header(
                  onBack: _dismiss,
                  splitEnabled: amount > 0,
                  hasSplits: state.splits.isNotEmpty,
                  onSplit: () => showSplitSheet(
                    context,
                    amount: amount,
                    initial: state.splits,
                    onChanged: controller.setSplits,
                  ),
                ),
                const SizedBox(height: 6),
                AmountDisplay(value: state.amount),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(child: _SectionLabel(text: 'CATEGORY')),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pageInsetOf(context),
              0,
              pageInsetOf(context),
              10,
            ),
            sliver: SliverToBoxAdapter(
              child: categoriesAsync.when(
                loading: () => const _CategorySkeleton(),
                error: (e, _) => _CategoryError(
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
                data: (cats) => CategoryGrid(
                  categories: cats
                      .where(
                        (c) => c.key != 'income' && c.key != 'subscriptions',
                      )
                      .toList(),
                  selectedId: state.categoryId,
                  onSelect: controller.selectCategory,
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(child: _SectionLabel(text: 'NOTE')),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pageInsetOf(context),
              0,
              pageInsetOf(context),
              10,
            ),
            sliver: SliverToBoxAdapter(
              child: _NoteField(onChanged: controller.setNote),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: Numpad(
                onDigit: controller.pressDigit,
                onDot: controller.pressDot,
                onBackspace: controller.pressBackspace,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              16 + (widget.embedded ? MediaQuery.paddingOf(context).bottom : 0),
            ),
            sliver: SliverToBoxAdapter(
              child: _SaveButton(
                enabled: state.canSave,
                saving: state.saving,
                error: state.error,
                onTap: controller.save,
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return ColoredBox(color: AppColors.background, child: body);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemOverlays.background(context),
      child: Scaffold(backgroundColor: AppColors.background, body: body),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final bool splitEnabled;
  final bool hasSplits;
  final VoidCallback onSplit;

  const _Header({
    required this.onBack,
    required this.splitEnabled,
    required this.hasSplits,
    required this.onSplit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pageInsetOf(context),
        2,
        pageInsetOf(context),
        10,
      ),
      child: Row(
        children: [
          HeaderBackButton.onSurface(onTap: onBack),
          const SizedBox(width: 4),
          Text('Add Expense', style: AppTextStyles.titleM),
          const Spacer(),
          _SplitButton(
            enabled: splitEnabled,
            active: hasSplits,
            onTap: onSplit,
          ),
        ],
      ),
    );
  }
}

/// Header action that opens the split sheet. Disabled (greyed, non-tappable)
/// until the user has entered a positive amount; shows an accent dot once at
/// least one split share exists.
class _SplitButton extends StatelessWidget {
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  const _SplitButton({
    required this.enabled,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.primary : AppColors.inkFaint;
    return Semantics(
      button: true,
      enabled: enabled,
      label: active ? 'Split expense, active' : 'Split expense',
      child: Material(
        color: enabled ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.call_split_rounded, size: 20, color: fg),
                ),
                if (enabled && active)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section label (CATEGORY / NOTE) ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.muted.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Note input ──────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _NoteField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      maxLength: 140,
      maxLines: 1,
      style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13.5),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'What was this for?',
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkLight),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Save button ─────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool saving;
  final String? error;
  final VoidCallback onTap;

  const _SaveButton({
    required this.enabled,
    required this.saving,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Text(
            error!,
            style: AppTextStyles.label.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? AppColors.accent : AppColors.inkFaint,
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.27),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Save Expense',
                    style: AppTextStyles.labelStrong.copyWith(
                      fontSize: 15.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Category states ─────────────────────────────────────────────────────────

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, _) => Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.inkFaint,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CategoryError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text('Could not load categories', style: AppTextStyles.bodyStrong),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
