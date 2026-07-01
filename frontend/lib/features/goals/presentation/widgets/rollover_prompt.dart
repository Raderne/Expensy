import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../../application/rollovers_controller.dart';
import '../../domain/budget_rollover.dart';
import 'allocate_rollover_sheet.dart';

/// Shows one card per closed month with leftover budget, each opening the
/// allocate-to-goal sheet. Hides itself when there's nothing to allocate.
class RolloverPrompt extends ConsumerWidget {
  const RolloverPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollovers =
        ref.watch(rolloversControllerProvider).value ??
        const <BudgetRollover>[];
    if (rollovers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        children: [
          for (final r in rollovers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RolloverCard(
                rollover: r,
                onAllocate: () => _openAllocate(context, r),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openAllocate(BuildContext context, BudgetRollover r) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => AllocateRolloverSheet(rollover: r),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leftover added to goal'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

class _RolloverCard extends StatelessWidget {
  final BudgetRollover rollover;
  final VoidCallback onAllocate;

  const _RolloverCard({required this.rollover, required this.onAllocate});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final monthLabel = DateFormat('MMMM').format(rollover.monthDate);

    return GlassCard(
      radius: 18,
      blur: 24,
      tint: AppColors.accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.savings_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${money.format(rollover.remaining)} left in $monthLabel',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  'Move it into a savings goal',
                  style: AppTextStyles.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AllocateButton(onTap: onAllocate),
        ],
      ),
    );
  }
}

class _AllocateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AllocateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            'Allocate',
            style: AppTextStyles.labelStrong.copyWith(
              color: AppColors.accent,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
