import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/collapsing_hero.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/auth_user.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../income/application/income_controller.dart';
import '../../income/presentation/widgets/add_side_income_sheet.dart';
import '../../recurring_expenses/application/recurring_expenses_controller.dart';
import '../../settings/application/theme_controller.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/edit_budget_sheet.dart';
import 'widgets/edit_name_sheet.dart';
import 'widgets/edit_sheet_shell.dart';

/// Reads the app version baked into the build at compile time (from
/// `pubspec.yaml`'s `version:`), so the About section never drifts from the
/// actual installed build.
final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final dash = ref.watch(dashboardControllerProvider);
    final incomeAsync = ref.watch(incomeControllerProvider);
    final recurringAsync = ref.watch(recurringExpensesControllerProvider);
    final appVersion = switch (ref.watch(_appVersionProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };

    final user = switch (auth.value) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final budgetAmount = switch (dash) {
      AsyncData(:final value) => value.summary.budget.amount,
      _ => 0.0,
    };
    final lifetimeBalance = switch (dash) {
      AsyncData(:final value) => value.summary.balance,
      _ => 0.0,
    };
    final incomeSummary = switch (incomeAsync) {
      AsyncData(:final value) when value.activeCount > 0 =>
        '${value.activeCount} source${value.activeCount == 1 ? '' : 's'} · ${NumberFormat.simpleCurrency(decimalDigits: 0).format(value.activeMonthlyTotal)}/mo',
      _ => 'Not set',
    };
    final recurringSummary = switch (recurringAsync) {
      AsyncData(:final value) when value.activeCount > 0 =>
        '${value.activeCount} active · ${NumberFormat.simpleCurrency(decimalDigits: 0).format(value.activeMonthlyTotal)}/mo',
      _ => 'None set',
    };
    final topInset = MediaQuery.paddingOf(context).top;

    return CustomScrollView(
      slivers: [
        SliverCollapsingHero(
          minHeight: topInset + 56,
          maxHeight: topInset + 220,
          expanded: _ProfileHeroExpanded(topInset: topInset, user: user),
          collapsed: _ProfileHeroCollapsed(topInset: topInset, name: user.name),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          sliver: SliverList.list(
            children: [
              _SectionCard(
                title: 'Account',
                children: [
                  _Row(
                    icon: Icons.badge_outlined,
                    label: 'Name',
                    value: user.name,
                    onTap: () => _openEditName(context, user.name),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: user.email,
                    trailing: const _MutedTag(label: 'Read-only'),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.lock_outline_rounded,
                    label: 'Password',
                    value: '••••••••',
                    onTap: () => _openChangePassword(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Appearance',
                children: [
                  _Row(
                    icon: Icons.palette_outlined,
                    label: 'Theme & widgets',
                    value: ref.watch(themeModeProvider).label,
                    onTap: () => context.push('/profile/appearance'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Money',
                children: [
                  _Row(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Total balance',
                    value: NumberFormat.simpleCurrency(
                      decimalDigits: 0,
                    ).format(lifetimeBalance),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.savings_outlined,
                    label: 'Monthly budget',
                    value: budgetAmount > 0
                        ? NumberFormat.simpleCurrency(
                            decimalDigits: 0,
                          ).format(budgetAmount)
                        : 'Not set',
                    onTap: () => _openEditBudget(context, budgetAmount),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.autorenew_rounded,
                    label: 'Recurring expenses',
                    value: recurringSummary,
                    onTap: () => context.push('/profile/recurring-expenses'),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.payments_outlined,
                    label: 'Income sources',
                    value: incomeSummary,
                    onTap: () => context.push('/profile/income-sources'),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add side income',
                    value: 'Freelance, gifts, one-offs',
                    onTap: () => _openAddSideIncome(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'About',
                children: [
                  _Row(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & feedback',
                    value: 'github.com/Raderne',
                    onTap: () => _showComingSoon(context),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.info_outline_rounded,
                    label: 'App version',
                    value: appVersion != null ? 'v$appVersion' : '—',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SignOutButton(onTap: () => _confirmSignOut(context, ref)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Sheet launchers ───────────────────────────────────────────────────────

  Future<void> _openEditName(BuildContext context, String current) async {
    await showEditSheet<void>(
      context,
      (_) => EditNameSheet(initialName: current),
    );
  }

  Future<void> _openChangePassword(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showEditSheet<bool>(
      context,
      (_) => const ChangePasswordSheet(),
    );
    if (ok == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password updated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openEditBudget(BuildContext context, double current) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showEditSheet<bool>(
      context,
      (_) => EditBudgetSheet(initialAmount: current),
    );
    if (ok == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Budget updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _openAddSideIncome(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showEditSheet<bool>(
      context,
      (_) => const AddSideIncomeSheet(),
    );
    if (ok == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Side income added'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Sign out?', style: AppTextStyles.titleM),
        content: Text(
          'You will need to sign in again to access your data.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.inkMid,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign out',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _ProfileHeroExpanded extends StatelessWidget {
  final double topInset;
  final AuthUser user;

  const _ProfileHeroExpanded({required this.topInset, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, topInset + 8, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'Profile',
              style: AppTextStyles.titleM.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          _Avatar(name: user.name),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: AppTextStyles.titleM.copyWith(
              color: Colors.white,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact bar shown once the profile hero is scrolled away: back + full name.
class _ProfileHeroCollapsed extends StatelessWidget {
  final double topInset;
  final String name;

  const _ProfileHeroCollapsed({required this.topInset, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topInset, left: 22, right: 22),
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleM.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.titleM.copyWith(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    if (parts.length == 1) return first;
    final last = parts.last.characters.first.toUpperCase();
    return '$first$last';
  }
}

// ─── Section card + rows ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.muted.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.inkMid,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000C22),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.muted.copyWith(
                        fontSize: 11.5,
                        color: AppColors.inkMid,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null && tap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkLight,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

class _MutedTag extends StatelessWidget {
  final String label;
  const _MutedTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.mutedSmall.copyWith(
          color: AppColors.inkMid,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

// ─── Sign-out button ─────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dangerLight, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                'Sign out',
                style: AppTextStyles.labelStrong.copyWith(
                  fontSize: 14.5,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
