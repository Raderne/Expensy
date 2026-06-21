import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../application/upcoming_bills_controller.dart';
import '../../domain/upcoming_bill.dart';

class UpcomingBillsCard extends ConsumerWidget {
  const UpcomingBillsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingBillsControllerProvider);
    final list = upcomingAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <UpcomingBill>[],
    );
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        onTap: () => context.push('/profile/recurring-expenses'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Upcoming bills', style: AppTextStyles.titleS),
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
            ...List.generate(list.length, (i) {
              final b = list[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == list.length - 1 ? 0 : 10,
                ),
                child: _BillRow(bill: b),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final UpcomingBill bill;
  const _BillRow({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categories[bill.categoryKey]?.color ??
        _parseHex(bill.categoryColor) ??
        AppColors.primary;
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
                bill.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong,
              ),
              Text(
                _relativeDate(bill.occurredAt),
                style: AppTextStyles.muted.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
        Text(
          '-${money.format(bill.amount)}',
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }

  static String _relativeDate(DateTime d) {
    final today = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = day.difference(t).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return 'In $diff days';
    return DateFormat('MMM d').format(d);
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    final v = int.tryParse(clean, radix: 16);
    if (v == null) return null;
    return Color(clean.length == 6 ? 0xFF000000 | v : v);
  }
}
