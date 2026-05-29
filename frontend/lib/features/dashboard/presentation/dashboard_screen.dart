import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_summary.dart';
import 'widgets/balance_card.dart';
import 'widgets/budget_card.dart';
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

    return dashState.when(
      loading: () => _DashboardScaffold(
        name: name,
        child: _SkeletonBody(),
      ),
      error: (e, _) => _DashboardScaffold(
        name: name,
        child: _ErrorBody(onRetry: () => ref.read(dashboardControllerProvider.notifier).refresh()),
      ),
      data: (state) => RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
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

    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _Hero(name: name, topInset: topInset, summary: state.summary),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BudgetCard(budget: state.summary.budget),
              const SizedBox(height: 14),
              RecentTransactionsSection(transactions: state.recentTransactions),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Hero section ────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final String name;
  final double topInset;
  final DashboardSummary summary;

  const _Hero({required this.name, required this.topInset, required this.summary});

  @override
  Widget build(BuildContext context) {
    return HeroGradient(
      padding: EdgeInsets.fromLTRB(22, topInset + 4, 22, 22),
      child: Column(
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
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
      ),
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
          _SkeletonBox(height: 80, radius: 16),
          SizedBox(height: 14),
          _SkeletonBox(height: 20, width: 160),
          SizedBox(height: 12),
          _SkeletonBox(height: 60),
          SizedBox(height: 8),
          _SkeletonBox(height: 60),
          SizedBox(height: 8),
          _SkeletonBox(height: 60),
          SizedBox(height: 8),
          _SkeletonBox(height: 60),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const _SkeletonBox({required this.height, this.width, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.inkFaint,
        borderRadius: BorderRadius.circular(radius),
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
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.inkLight),
            const SizedBox(height: 12),
            Text('Could not load dashboard', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 4),
            Text('Check your connection and try again.', style: AppTextStyles.body),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
