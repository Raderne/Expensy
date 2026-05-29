import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/categories_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/add_expense_controller.dart';
import 'widgets/amount_display.dart';
import 'widgets/category_grid.dart';
import 'widgets/numpad.dart';
import 'widgets/success_view.dart';

class AddExpenseScreen extends ConsumerWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addExpenseControllerProvider);
    final controller = ref.read(addExpenseControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    // Trigger medium-impact haptic exactly once on save success.
    ref.listen<AddExpenseState>(addExpenseControllerProvider, (prev, next) {
      if (prev?.saved == null && next.saved != null) {
        HapticFeedback.mediumImpact();
      }
    });

    if (state.saved != null) {
      return SuccessView(
        transaction: state.saved!,
        onAddAnother: controller.reset,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _Header(onBack: () => context.go('/')),
              const SizedBox(height: 6),
              AmountDisplay(value: state.amount),
              const SizedBox(height: 14),
            ],
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(child: _SectionLabel(text: 'CATEGORY')),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          sliver: SliverToBoxAdapter(
            child: categoriesAsync.when(
              loading: () => const _CategorySkeleton(),
              error: (e, _) => _CategoryError(
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
              data: (cats) => CategoryGrid(
                categories: cats.where((c) => c.key != 'income').toList(),
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
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
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
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
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
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Row(
        children: [
          _BackButton(onTap: onBack),
          const SizedBox(width: 10),
          Text('Add Expense', style: AppTextStyles.titleM),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x17000000),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.ink,
            size: 22,
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
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.42,
      children: List.generate(
        6,
        (_) => Container(
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
