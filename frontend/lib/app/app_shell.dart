import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/system_overlays.dart';
import '../core/widgets/bottom_nav.dart';

/// Hosts the bottom nav and renders the current branch (child) above it.
/// Used as the [StatefulShellRoute] builder.
class AppShell extends StatelessWidget {
  final Widget child;
  final NavTab active;

  const AppShell({super.key, required this.child, required this.active});

  @override
  Widget build(BuildContext context) {
    // Screens that draw their own hero gradient under the status bar opt out
    // of the SafeArea top inset so the gradient bleeds to the top edge.
    final hasHero = active == NavTab.home || active == NavTab.profile;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasHero
          ? AppSystemOverlays.hero
          : AppSystemOverlays.lightBackground,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(top: !hasHero, bottom: false, child: child),
        bottomNavigationBar: BottomNav(
          active: active,
          onTap: (tab) => context.go(tab.path),
          onAdd: () => context.push('/add'),
        ),
      ),
    );
  }
}
