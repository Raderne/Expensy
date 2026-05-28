import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/bottom_nav.dart';

/// Hosts the bottom nav and renders the current branch (child) above it.
/// Used as the [StatefulShellRoute] builder.
class AppShell extends StatelessWidget {
  final Widget child;
  final NavTab active;

  const AppShell({super.key, required this.child, required this.active});

  static const _dashboardOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
  );

  static const _defaultOverlay = SystemUiOverlayStyle(
    statusBarColor: AppColors.surface,
    statusBarIconBrightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    final isDashboard = active == NavTab.home;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDashboard ? _dashboardOverlay : _defaultOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: !isDashboard,
          bottom: false,
          child: child,
        ),
        bottomNavigationBar: BottomNav(
          active: active,
          onTap: (tab) => context.go(tab.path),
        ),
      ),
    );
  }
}
