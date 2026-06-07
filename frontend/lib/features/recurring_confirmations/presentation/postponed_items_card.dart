import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/postponed_occurrences_controller.dart';
import '../domain/pending_occurrence.dart';

/// Dashboard card listing items the user pushed to a later day, with a Manage
/// action that opens the full postponed screen. Hidden when there are none.
class PostponedItemsCard extends ConsumerWidget {
  const PostponedItemsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(postponedOccurrencesControllerProvider);
    final list = async.maybeWhen(
      data: (value) => value,
      orElse: () => const <PendingOccurrence>[],
    );
    if (list.isEmpty) return const SizedBox.shrink();

    // Keep the dashboard tidy: preview a few, the rest live on the Manage screen.
    final preview = list.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/postponed'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000C22),
                  blurRadius: 14,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Postponed', style: AppTextStyles.titleS),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${list.length}',
                        style: AppTextStyles.labelStrong.copyWith(
                          color: AppColors.accent,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Manage →',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(preview.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == preview.length - 1 ? 0 : 10,
                    ),
                    child: _PostponedRow(item: preview[i]),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostponedRow extends StatelessWidget {
  final PendingOccurrence item;
  const _PostponedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isIncome = item.isIncome;
    final color = isIncome ? AppColors.success : AppColors.danger;
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong,
              ),
              Text(
                _relativeDate(item.dueAt),
                style: AppTextStyles.muted.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
        Text(
          '${isIncome ? '+' : '-'}${money.format(item.amount)}',
          style: AppTextStyles.bodyStrong.copyWith(color: color),
        ),
      ],
    );
  }

  static String _relativeDate(DateTime d) {
    final today = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = day.difference(t).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff > 1 && diff < 7) return 'Due in $diff days';
    if (diff < 0) return 'Was due ${DateFormat('MMM d').format(d)}';
    return 'Due ${DateFormat('MMM d').format(d)}';
  }
}
