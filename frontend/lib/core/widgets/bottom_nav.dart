import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum NavTab { home, add, transactions, analytics }

extension NavTabPath on NavTab {
  String get path => switch (this) {
        NavTab.home => '/',
        NavTab.add => '/add',
        NavTab.transactions => '/transactions',
        NavTab.analytics => '/analytics',
      };
}

class BottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  const BottomNav({super.key, required this.active, required this.onTap});

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
              _NavItem(tab: NavTab.home, icon: Icons.home_rounded, label: 'Home', active: active, onTap: onTap),
              _NavItem(tab: NavTab.transactions, icon: Icons.receipt_long_rounded, label: 'List', active: active, onTap: onTap),
              _AddButton(onTap: () => onTap(NavTab.add)),
              _NavItem(tab: NavTab.analytics, icon: Icons.pie_chart_rounded, label: 'Stats', active: active, onTap: onTap),
              // Placeholder for a future profile tab; keeps spacing balanced with the centered + button.
              const SizedBox(width: 48),
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
    return InkResponse(
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
            Text(label, style: AppTextStyles.mutedSmall.copyWith(color: color)),
          ],
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
