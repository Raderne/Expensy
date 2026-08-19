import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/pane_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/update/update_controller.dart';
import '../../../core/update/update_sheet.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../contacts/data/contacts_repository.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../goals/application/goals_controller.dart';
import '../../goals/domain/goal.dart';
import '../../income/application/income_controller.dart';
import '../../income/presentation/widgets/add_side_income_sheet.dart';
import '../../recurring_expenses/application/recurring_expenses_controller.dart';
import '../../settings/application/theme_controller.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/edit_budget_sheet.dart';
import 'widgets/edit_name_sheet.dart';
import 'widgets/edit_opening_balance_sheet.dart';
import 'widgets/edit_sheet_shell.dart';

/// Reads the app version baked into the build at compile time (from
/// `pubspec.yaml`'s `version:`), so the About section never drifts from the
/// actual installed build.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// The grouped settings rows. No scroll view of its own — the compact screen
/// hands it to a sliver under the collapsing hero, and the expanded pane wraps
/// it in a [ProfileSettingsPane].
class ProfileSettingsList extends ConsumerWidget {
  const ProfileSettingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenForUpdateResults(context, ref);

    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final auth = ref.watch(authControllerProvider);
    final dash = ref.watch(dashboardControllerProvider);
    final incomeAsync = ref.watch(incomeControllerProvider);
    final recurringAsync = ref.watch(recurringExpensesControllerProvider);
    final appVersion = switch (ref.watch(appVersionProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final updateState = ref.watch(updateControllerProvider);

    final user = switch (auth.value) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
        '${value.activeCount} source${value.activeCount == 1 ? '' : 's'} · ${money.format(value.activeMonthlyTotal)}/mo',
      _ => 'Not set',
    };
    final recurringSummary = switch (recurringAsync) {
      AsyncData(:final value) when value.activeCount > 0 =>
        '${value.activeCount} active · ${money.format(value.activeMonthlyTotal)}/mo',
      _ => 'None set',
    };
    final goals = ref.watch(goalsControllerProvider).value ?? const <Goal>[];
    final goalsSummary = goals.isEmpty
        ? 'Set a savings goal'
        : '${goals.length} ${goals.length == 1 ? 'goal' : 'goals'} · ${money.format(goals.totalSaved)} saved';
    final contactCount = ref.watch(contactsViewProvider).value?.length ?? 0;
    final peopleSummary = contactCount > 0
        ? '$contactCount ${contactCount == 1 ? 'person' : 'people'}'
        : 'Split bills with friends';

    return Column(
      children: [
        SectionCard(
          title: 'Account',
          children: [
            SettingsRow(
              icon: Icons.badge_outlined,
              label: 'Name',
              value: user.name,
              onTap: () => _openEditName(context, user.name),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: user.email,
              trailing: const _MutedTag(label: 'Read-only'),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.lock_outline_rounded,
              label: 'Password',
              value: '••••••••',
              onTap: () => _openChangePassword(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Money',
          children: [
            SettingsRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total balance',
              value: money.format(lifetimeBalance),
              onTap: () =>
                  _openEditOpeningBalance(context, user.openingBalance),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.savings_outlined,
              label: 'Monthly budget',
              value: budgetAmount > 0 ? money.format(budgetAmount) : 'Not set',
              onTap: () => _openEditBudget(context, budgetAmount),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.flag_outlined,
              label: 'Goals',
              value: goalsSummary,
              onTap: () => context.push('/profile/goals'),
              route: '/profile/goals',
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.autorenew_rounded,
              label: 'Recurring expenses',
              value: recurringSummary,
              onTap: () => context.push('/profile/recurring-expenses'),
              route: '/profile/recurring-expenses',
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.payments_outlined,
              label: 'Income sources',
              value: incomeSummary,
              onTap: () => context.push('/profile/income-sources'),
              route: '/profile/income-sources',
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add side income',
              value: 'Freelance, gifts, one-offs',
              onTap: () => _openAddSideIncome(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Shared',
          children: [
            SettingsRow(
              icon: Icons.group_outlined,
              label: 'People',
              value: peopleSummary,
              onTap: () => context.push('/profile/contacts'),
              route: '/profile/contacts',
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.handshake_outlined,
              label: 'Who owes me',
              value: 'Track split bills & repayments',
              onTap: () => context.push('/shared'),
              route: '/shared',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Appearance',
          children: [
            SettingsRow(
              icon: Icons.palette_outlined,
              label: 'Theme & widgets',
              value: ref.watch(themeModeProvider).label,
              onTap: () => context.push('/profile/appearance'),
              route: '/profile/appearance',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'About',
          children: [
            SettingsRow(
              icon: Icons.help_outline_rounded,
              label: 'Help & feedback',
              value: 'github.com/Raderne',
              onTap: () => _showComingSoon(context),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.info_outline_rounded,
              label: 'App version',
              value: appVersion != null ? 'v$appVersion' : '—',
            ),
            const SettingsDivider(),
            _UpdateRow(state: updateState),
          ],
        ),
        const SizedBox(height: 18),
        _SignOutButton(onTap: () => _confirmSignOut(context, ref)),
      ],
    );
  }

  void _listenForUpdateResults(BuildContext context, WidgetRef ref) {
    ref.listen<UpdateState>(updateControllerProvider, (_, next) {
      if (!context.mounted) return;
      // While the sheet is open it already surfaces progress/errors inline;
      // skip the snackbar to avoid a redundant one behind it.
      final sheetVisible = ref.read(updateSheetVisibleProvider);
      if (next is UpdateAvailable) {
        showUpdateSheet(context, ref, next.info);
      } else if (next is UpdateUpToDate && !sheetVisible) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on the latest version")),
        );
      } else if (next is UpdateError && !sheetVisible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });
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

  Future<void> _openEditOpeningBalance(
    BuildContext context,
    double current,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showEditSheet<bool>(
      context,
      (_) => EditOpeningBalanceSheet(initialAmount: current),
    );
    if (ok == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Balance updated'),
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

/// Expanded shell's left pane on Me: the settings list in its own scroll view.
class ProfileSettingsPane extends StatelessWidget {
  const ProfileSettingsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        pageInsetOf(context),
        16,
        pageInsetOf(context),
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [ProfileSettingsList()],
    );
  }
}

// ─── Section card + rows ─────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

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

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Route this row opens. In a two-pane layout the detail lands in the
  /// companion pane, so the row marks itself selected while it is showing —
  /// without it, a list-detail split leaves no trace of where the right-hand
  /// content came from.
  final String? route;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    final selected =
        route != null && PaneScope.isDetailSelected(context, route!);
    return Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
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
                  selected
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? AppColors.primary : AppColors.inkLight,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

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

// ─── Update row ──────────────────────────────────────────────────────────────

class _UpdateRow extends ConsumerWidget {
  final UpdateState state;
  const _UpdateRow({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color, onTap) = switch (state) {
      UpdateChecking() => (
        'Checking…',
        AppColors.inkMid,
        null as VoidCallback?,
      ),
      UpdateUpToDate() => (
        'Up to date',
        AppColors.success,
        () => ref.read(updateControllerProvider.notifier).checkForUpdate(),
      ),
      UpdateAvailable(:final info) => (
        'v${info.version} available',
        AppColors.primary,
        () => showUpdateSheet(context, ref, info),
      ),
      UpdateDownloading(:final info, :final progress) => (
        'Downloading ${(progress * 100).toInt()}%',
        AppColors.primary,
        () => showUpdateSheet(context, ref, info),
      ),
      UpdateVerifying(:final info) => (
        'Verifying…',
        AppColors.primary,
        () => showUpdateSheet(context, ref, info),
      ),
      UpdateReadyToInstall(:final info) => (
        'v${info.version} — tap to install',
        AppColors.success,
        () => showUpdateSheet(context, ref, info),
      ),
      UpdateError() => (
        'Tap to retry',
        AppColors.danger,
        () => ref.read(updateControllerProvider.notifier).checkForUpdate(),
      ),
      UpdateIdle() => (
        'Tap to check',
        AppColors.inkMid,
        () => ref.read(updateControllerProvider.notifier).checkForUpdate(),
      ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
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
                child: state is UpdateChecking
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    : const Icon(
                        Icons.system_update_alt_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check for updates',
                      style: AppTextStyles.muted.copyWith(
                        fontSize: 11.5,
                        color: AppColors.inkMid,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
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
