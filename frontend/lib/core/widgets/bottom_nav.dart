import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

enum NavTab { home, add, transactions, analytics, profile }

extension NavTabPath on NavTab {
  String get path => switch (this) {
    NavTab.home => '/',
    NavTab.add => '/add',
    NavTab.transactions => '/transactions',
    NavTab.analytics => '/analytics',
    NavTab.profile => '/profile',
  };
}

/// Frosted-glass tab bar with a centered, prominent orange FAB.
///
/// Rendered as a translucent blurred bar so the ambient background and scrolling
/// content read through it (the host Scaffold uses `extendBody: true`).
class BottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  /// Invoked by the center "+" button. Add Expense is a modal route rather than
  /// a tab, so it gets its own callback instead of going through [onTap].
  final VoidCallback onAdd;

  const BottomNav({
    super.key,
    required this.active,
    required this.onTap,
    required this.onAdd,
  });

  void _switchTab(NavTab tab) {
    // Selection-style click — soft tick that matches iOS / Android tab-bar
    // expectations. Only fires when the user actually changes tabs so
    // tapping the already-active tab stays silent.
    if (tab != active) HapticFeedback.selectionClick();
    onTap(tab);
  }

  void _pressAdd() {
    HapticFeedback.selectionClick();
    onAdd();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: 0.72),
            border: Border(top: BorderSide(color: c.glassBorder, width: 0.8)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    tab: NavTab.home,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: active,
                    onTap: _switchTab,
                  ),
                  _NavItem(
                    tab: NavTab.transactions,
                    icon: Icons.receipt_long_rounded,
                    label: 'List',
                    active: active,
                    onTap: _switchTab,
                  ),
                  _AddButton(onTap: _pressAdd),
                  _NavItem(
                    tab: NavTab.analytics,
                    icon: Icons.pie_chart_rounded,
                    label: 'Stats',
                    active: active,
                    onTap: _switchTab,
                  ),
                  _NavItem(
                    tab: NavTab.profile,
                    icon: Icons.person_rounded,
                    label: 'Me',
                    active: active,
                    onTap: _switchTab,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavTab tab;
  final IconData icon;
  final String label;
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  const _NavItem({
    required this.tab,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == tab;
    final color = isActive ? AppColors.primary : AppColors.inkLight;
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      // Drop the child's own semantics — its Text would otherwise add a
      // duplicate "Home/Home" announcement under our explicit label.
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(tab),
        radius: 30,
        child: SizedBox(
          width: 58,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.mutedSmall.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add expense',
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFB8C3E), AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
