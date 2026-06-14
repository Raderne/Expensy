import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/update/auto_update.dart';
import '../../../core/update/update_controller.dart';
import '../../../core/update/update_sheet.dart';
import '../../../core/update/whats_new.dart';
import '../../../core/widgets/collapsing_hero.dart';
import '../../../core/widgets/haptic_refresh.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../recurring_confirmations/application/pending_occurrences_controller.dart';
import '../../recurring_confirmations/presentation/confirmation_queue.dart';
import '../../recurring_confirmations/presentation/postponed_items_card.dart';
import '../../recurring_expenses/presentation/widgets/upcoming_bills_card.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_summary.dart';
import 'widgets/balance_card.dart';
import 'widgets/budget_card.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/recent_transactions_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final name = switch (auth.value) {
      AuthAuthenticated(:final user) => user.name,
      _ => '',
    };
    final dashState = ref.watch(dashboardControllerProvider);

    // Show the "What's new" notes once after an in-app update lands. Runs before
    // the confirmation queue so the two modals don't collide; its own one-shot
    // guard prevents repeats.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) maybeShowWhatsNew(context, ref);
    });

    // Weekly auto-check: fires on cold start if ≥7 days since the last check.
    // Runs after What's New to avoid two sheets at once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) maybeAutoCheckOnLaunch(ref);
    });

    // When the auto-check (or any check) finds an update while the dashboard is
    // visible, show the update sheet immediately.
    ref.listen(updateControllerProvider, (_, next) {
      if (next is! UpdateAvailable) return;
      if (ref.read(updateSheetVisibleProvider)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showUpdateSheet(context, ref, next.info);
      });
    });

    // Auto-prompt the user to confirm/postpone any due recurring items once the
    // dashboard is up. The queue runner guards against double-presentation.
    ref.watch(pendingOccurrencesControllerProvider);
    ref.listen(pendingOccurrencesControllerProvider, (_, next) {
      final due = next.maybeWhen(
        data: (value) => value,
        orElse: () => const [],
      );
      if (due.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) runConfirmationQueue(context);
      });
    });

    return dashState.when(
      loading: () => Shimmer(
        child: _DashboardScaffold(name: name, child: _SkeletonBody()),
      ),
      error: (e, _) => _DashboardScaffold(
        name: name,
        child: _ErrorBody(
          onRetry: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
      ),
      data: (state) => RefreshIndicator(
        onRefresh: withRefreshHaptic(
          () => ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
        color: AppColors.primary,
        child: _DashboardContent(name: name, state: state),
      ),
    );
  }
}

// ─── Loaded content ─────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final String name;
  final DashboardState state;

  const _DashboardContent({required this.name, required this.state});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final isFirstRun = _isFirstRun(state);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverCollapsingHero(
          minHeight: topInset + 56,
          // The expanded content (greeting row + balance card) is bottom-
          // anchored, so if it's taller than maxHeight the overflow eats the
          // top padding and the greeting slides up behind the status bar. Give
          // it enough room to clear the inset. minHeight is unchanged, so the
          // collapsed bar doesn't gain any extra space.
          maxHeight: topInset + 290,
          expanded: _HeroExpanded(
            name: name,
            topInset: topInset,
            summary: state.summary,
          ),
          collapsed: _HeroCollapsed(name: name, topInset: topInset),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isFirstRun) ...[
                const OnboardingCard(),
                const SizedBox(height: 14),
              ],
              BudgetCard(budget: state.summary.budget),
              const SizedBox(height: 14),
              const UpcomingBillsCard(),
              const PostponedItemsCard(),
              // When the onboarding card is showing the dashboard already has a
              // primary CTA; the section's own empty state would be redundant.
              if (!isFirstRun)
                RecentTransactionsSection(
                  transactions: state.recentTransactions,
                ),
            ]),
          ),
        ),
      ],
    );
  }

  /// True only for users with no recorded activity ever. Once any transaction
  /// is materialized (recurring income, side income, an added expense) the
  /// onboarding banner steps aside for the real dashboard.
  static bool _isFirstRun(DashboardState state) {
    final s = state.summary;
    return state.recentTransactions.isEmpty &&
        s.balance == 0 &&
        s.income == 0 &&
        s.expenses == 0;
  }
}

// ─── Hero section ────────────────────────────────────────────────────────────

class _HeroExpanded extends StatelessWidget {
  final String name;
  final double topInset;
  final DashboardSummary summary;

  const _HeroExpanded({
    required this.name,
    required this.topInset,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, topInset + 4, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    name,
                    style: AppTextStyles.titleM.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              _AvatarPill(),
            ],
          ),
          const SizedBox(height: 14),
          BalanceCard(summary: summary),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning,';
    if (h >= 12 && h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

/// Compact bar shown once the hero is scrolled away: full name + profile button.
class _HeroCollapsed extends StatelessWidget {
  final String name;
  final double topInset;

  const _HeroCollapsed({required this.name, required this.topInset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topInset, left: 22, right: 22),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleM.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _AvatarPill(),
          ],
        ),
      ),
    );
  }
}

class _AvatarPill extends StatelessWidget {
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

// ─── Scaffold shared by loading/error states ─────────────────────────────────

class _DashboardScaffold extends StatelessWidget {
  final String name;
  final Widget child;

  const _DashboardScaffold({required this.name, required this.child});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        HeroGradient(
          padding: EdgeInsets.fromLTRB(22, topInset + 4, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name.isNotEmpty ? name : '  ',
                    style: AppTextStyles.titleM.copyWith(color: Colors.white),
                  ),
                  _AvatarPill(),
                ],
              ),
              const SizedBox(height: 14),
              _HeroPlaceholder(),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      height: 130,
      radius: 22,
      baseColor: Colors.white.withValues(alpha: 0.10),
      shineColor: Colors.white.withValues(alpha: 0.22),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _SkeletonBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 80, radius: 16),
          SizedBox(height: 14),
          ShimmerBox(height: 20, width: 160),
          SizedBox(height: 12),
          ShimmerBox(height: 60),
          SizedBox(height: 8),
          ShimmerBox(height: 60),
          SizedBox(height: 8),
          ShimmerBox(height: 60),
          SizedBox(height: 8),
          ShimmerBox(height: 60),
        ],
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.inkLight),
            const SizedBox(height: 12),
            Text('Could not load dashboard', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}
