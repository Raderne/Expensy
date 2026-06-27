import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../application/goals_controller.dart';
import '../../domain/goal.dart';

/// Compact savings-goals summary for the dashboard. Renders nothing until the
/// user has at least one goal; taps through to the full Goals screen.
class GoalsSummaryCard extends ConsumerWidget {
  const GoalsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsControllerProvider).value ?? const <Goal>[];
    if (goals.isEmpty) return const SizedBox.shrink();

    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    // Show the goals furthest from done first — they need the most attention.
    final preview = [...goals]..sort((a, b) => a.progress.compareTo(b.progress));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        onTap: () => context.push('/profile/goals'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Savings goals', style: AppTextStyles.titleS),
                const Spacer(),
                Text(
                  'View all →',
                  style: AppTextStyles.label.copyWith(color: AppColors.accent),
                ),
                const SizedBox(width: 4),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${money.format(goals.totalSaved)} saved of ${money.format(goals.totalTarget)}',
              style: AppTextStyles.muted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...preview
                .take(2)
                .map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MiniRow(goal: g),
                    )),
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final Goal goal;
  const _MiniRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = goal.colorValue;
    return Row(
      children: [
        Icon(goal.iconData, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            goal.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.glassBorder),
                    child: const SizedBox.expand(),
                  ),
                  FractionallySizedBox(
                    widthFactor: goal.progress.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: DecoratedBox(decoration: BoxDecoration(color: color)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${goal.pct}%',
          style: AppTextStyles.mutedSmall.copyWith(color: AppColors.inkMid),
        ),
      ],
    );
  }
}
