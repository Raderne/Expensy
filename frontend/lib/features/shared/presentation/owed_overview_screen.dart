import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/collapsing_hero.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../contacts/domain/contact.dart';
import '../../contacts/presentation/contacts_screen.dart';
import '../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../application/owed_controller.dart';
import '../domain/owed_overview.dart';
import 'widgets/settle_sheet.dart';

class OwedOverviewScreen extends ConsumerWidget {
  const OwedOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(owedControllerProvider);
    final topInset = MediaQuery.paddingOf(context).top;
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final total = async.value?.totalOutstanding ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverCollapsingHero(
            minHeight: topInset + 56,
            maxHeight: topInset + 150,
            expanded: Padding(
              padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(context, 'Who owes me'),
                  const SizedBox(height: 16),
                  Text(
                    'Total owed to you',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    money.format(total),
                    style: AppTextStyles.heroAmount,
                  ),
                ],
              ),
            ),
            collapsed: Padding(
              padding: EdgeInsets.only(top: topInset, left: 18, right: 18),
              child: SizedBox(height: 56, child: _header(context, 'Who owes me')),
            ),
          ),
          async.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, _) => SliverFillRemaining(
              child: Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(owedControllerProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
            data: (overview) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              sliver: overview.contacts.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyState())
                  : SliverList.list(
                      children: [
                        for (final c in overview.contacts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ContactGroup(contact: c),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title) => Row(
    children: [
      HeaderBackButton.onHero(onTap: () => context.pop()),
      const Spacer(),
      Text(title, style: AppTextStyles.titleM.copyWith(color: Colors.white)),
      const Spacer(),
      const SizedBox(width: 44),
    ],
  );
}

class _ContactGroup extends ConsumerWidget {
  final OwedContact contact;
  const _ContactGroup({required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final avatarContact = Contact(
      id: contact.contactId,
      name: contact.contactName,
      color: contact.contactColor,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x10000C22), blurRadius: 14, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 10),
            child: Row(
              children: [
                ContactAvatar(contact: avatarContact),
                const SizedBox(width: 12),
                Expanded(child: Text(contact.contactName, style: AppTextStyles.titleS)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('owes you', style: AppTextStyles.mutedSmall),
                    Text(
                      money.format(contact.outstanding),
                      style: AppTextStyles.titleS.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border, indent: 70),
          for (final s in contact.splits)
            _SplitRow(split: s, contactName: contact.contactName),
        ],
      ),
    );
  }
}

class _SplitRow extends ConsumerWidget {
  final OwedSplit split;
  final String contactName;
  const _SplitRow({required this.split, required this.contactName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 2);
    final progress = split.owedAmount > 0 ? split.settledAmount / split.owedAmount : 0.0;
    final color = _parseHex(split.categoryColor);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(split.label, style: AppTextStyles.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  split.settledAmount > 0
                      ? '${money.format(split.settledAmount)} of ${money.format(split.owedAmount)} repaid · ${DateFormat('MMM d').format(split.occurredAt)}'
                      : '${money.format(split.owedAmount)} · ${DateFormat('MMM d').format(split.occurredAt)}',
                  style: AppTextStyles.mutedSmall,
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 4,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SettleButton(
            label: money.format(split.remaining),
            onTap: () => _settle(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _settle(BuildContext context, WidgetRef ref) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => SettleSheet(split: split, contactName: contactName),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repayment recorded'), backgroundColor: AppColors.success),
      );
    }
  }

  static Color _parseHex(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _SettleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Settle $label',
              style: AppTextStyles.labelStrong.copyWith(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 26),
          ),
          const SizedBox(height: 12),
          Text('All settled up', style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'When you split an expense, the part others owe you shows up here until they pay you back.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
