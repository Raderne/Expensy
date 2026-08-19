import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/hero_gradient.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/dashboard_summary.dart';
import 'balance_card.dart';

/// Greeting row + balance card. Shared by the compact collapsing hero and the
/// expanded shell's header band so the two can never drift apart.
class DashboardHeroContent extends StatelessWidget {
  final String name;
  final double topInset;
  final DashboardSummary summary;

  /// Lay the balance card out across the width instead of stacking it. Used by
  /// the expanded header band, which is short and wide rather than tall.
  final bool wide;

  const DashboardHeroContent({
    super.key,
    required this.name,
    required this.topInset,
    required this.summary,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        heroInsetOf(context),
        topInset + 4,
        heroInsetOf(context),
        wide ? 18 : 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingForNow(),
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleM.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const DashboardAvatarPill(),
            ],
          ),
          SizedBox(height: wide ? 12 : 14),
          BalanceCard(summary: summary, wide: wide),
        ],
      ),
    );
  }
}

/// Full-width header band for the expanded shell: the same hero content, on the
/// same gradient, spanning the whole content area rather than one pane.
///
/// It does not collapse on scroll the way the compact hero does — there is no
/// single scroll view under it any more, and on an 832 dp-tall display a ~190 dp
/// band is not worth reclaiming.
class DashboardHeaderBar extends ConsumerWidget {
  const DashboardHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final name = switch (ref.watch(authControllerProvider).value) {
      AuthAuthenticated(:final user) => user.name,
      _ => '',
    };
    final summary = ref.watch(dashboardViewProvider).value?.summary;

    return DecoratedBox(
      decoration: HeroGradient.decoration,
      child: summary == null
          ? _HeaderSkeleton(name: name, topInset: topInset)
          : DashboardHeroContent(
              name: name,
              topInset: topInset,
              summary: summary,
              wide: true,
            ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  final String name;
  final double topInset;

  const _HeaderSkeleton({required this.name, required this.topInset});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          heroInsetOf(context),
          topInset + 4,
          heroInsetOf(context),
          18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name.isNotEmpty ? name : '  ',
                  style: AppTextStyles.titleM.copyWith(color: Colors.white),
                ),
                const DashboardAvatarPill(),
              ],
            ),
            const SizedBox(height: 12),
            ShimmerBox(
              height: 96,
              radius: 22,
              baseColor: Colors.white.withValues(alpha: 0.10),
              shineColor: Colors.white.withValues(alpha: 0.22),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardAvatarPill extends StatelessWidget {
  const DashboardAvatarPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile',
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => context.go('/profile'),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Good morning,';
  if (h >= 12 && h < 18) return 'Good afternoon,';
  return 'Good evening,';
}
