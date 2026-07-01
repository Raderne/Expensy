import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/system_overlays.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/profile/presentation/widgets/edit_opening_balance_sheet.dart';
import '../features/profile/presentation/widgets/edit_sheet_shell.dart';

/// Hosts the bottom nav and renders the current branch (child) above it.
/// Used as the [ShellRoute] builder.
///
/// On first entry after login it nudges the user to set an opening balance if
/// it's still unset (0). Dismissing it won't re-prompt until the next login —
/// the shell (and this one-shot flag) is torn down on logout and rebuilt fresh
/// when the user signs back in.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final NavTab active;

  const AppShell({super.key, required this.child, required this.active});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _promptedOpeningBalance = false;

  void _maybePromptOpeningBalance() {
    if (_promptedOpeningBalance) return;
    final auth = ref.read(authControllerProvider).value;
    if (auth is! AuthAuthenticated) return;
    if (auth.user.openingBalance != 0) return;

    // Latch immediately so we prompt at most once per login session.
    _promptedOpeningBalance = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showEditSheet<bool>(
        context,
        (_) => const EditOpeningBalanceSheet(initialAmount: 0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybePromptOpeningBalance();

    // Screens that draw their own hero gradient under the status bar opt out
    // of the SafeArea top inset so the gradient bleeds to the top edge.
    final hasHero =
        widget.active == NavTab.home ||
        widget.active == NavTab.profile ||
        widget.active == NavTab.transactions;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasHero
          ? AppSystemOverlays.hero
          : AppSystemOverlays.background(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Let the body extend behind the translucent glass nav so the blurred
        // content reads through it. Scaffold folds the nav height into the
        // body's bottom MediaQuery padding, so scroll views still clear it.
        extendBody: true,
        body: AmbientBackground(
          child: SafeArea(top: !hasHero, bottom: false, child: widget.child),
        ),
        bottomNavigationBar: BottomNav(
          active: widget.active,
          onTap: (tab) => context.go(tab.path),
          onAdd: () => context.push('/add'),
        ),
      ),
    );
  }
}
