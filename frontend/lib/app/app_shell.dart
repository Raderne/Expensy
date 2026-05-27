import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/bottom_nav.dart';

/// Hosts the bottom nav and renders the current branch (child) above it.
/// Used as the [StatefulShellRoute] builder.
class AppShell extends StatelessWidget {
  final Widget child;
  final NavTab active;

  const AppShell({super.key, required this.child, required this.active});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: BottomNav(
        active: active,
        onTap: (tab) => context.go(tab.path),
      ),
    );
  }
}
