import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        radius: 28,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.mutedSmall.copyWith(color: color),
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
        radius: 32,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: AppColors.surface, size: 26),
        ),
      ),
    );
  }
}
