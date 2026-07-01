import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../profile/presentation/widgets/edit_opening_balance_sheet.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';

/// First-run onboarding banner. Shown on the Dashboard when the user hasn't
/// recorded a single transaction yet — disappears the moment any data lands
/// (income materialization, manual add, restored cache from another device).
///
/// We treat "first run" as `lifetime balance == 0` AND `no recent transactions`.
/// That avoids showing it to existing users whose current month happens to be
/// empty — a stricter signal than "no transactions this month".
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Welcome to Expensy. Tap the plus button at the bottom to add your first expense.',
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Expensy',
                        style: AppTextStyles.bodyStrong,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track every expense in a few taps.',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Add your first expense',
              child: GestureDetector(
                onTap: () => context.push('/add'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap + to add your first expense',
                        style: AppTextStyles.labelStrong.copyWith(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Set your starting balance',
              child: GestureDetector(
                onTap: () => showEditSheet<bool>(
                  context,
                  (_) => const EditOpeningBalanceSheet(initialAmount: 0),
                ),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    'Already have savings? Set your starting balance',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.primary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
