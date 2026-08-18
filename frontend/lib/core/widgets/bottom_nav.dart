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

/// Icon and label for a tab, shared by [BottomNav] and `AppNavRail` so the two
/// presentations of the same navigation cannot drift apart.
extension NavTabChrome on NavTab {
  IconData get icon => switch (this) {
    NavTab.home => Icons.home_rounded,
    NavTab.add => Icons.add_rounded,
    NavTab.transactions => Icons.receipt_long_rounded,
    NavTab.analytics => Icons.pie_chart_rounded,
    NavTab.profile => Icons.person_rounded,
  };

  String get label => switch (this) {
    NavTab.home => 'Home',
    NavTab.add => 'Add',
    NavTab.transactions => 'List',
    NavTab.analytics => 'Stats',
    NavTab.profile => 'Me',
  };
}

/// The four tabs that appear as destinations, in bar/rail order. [NavTab.add] is
/// excluded: Add Expense is an action, not a destination.
const List<NavTab> kNavDestinations = [
  NavTab.home,
  NavTab.transactions,
  NavTab.analytics,
  NavTab.profile,
];

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

  /// When true (expanded companion pane open), the FAB shows a selected ring.
  final bool addActive;

  const BottomNav({
    super.key,
    required this.active,
    required this.onTap,
    required this.onAdd,
    this.addActive = false,
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
            // Nav labels are already at the small end of the scale; letting the
            // system font size run all the way up bursts the fixed-height bar.
            // Clamp here (as Material does for its own nav bars) and let the
            // label clip beyond that rather than throw a layout overflow.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final tab in kNavDestinations.take(2))
                      _NavItem(tab: tab, active: active, onTap: _switchTab),
                    AddNavButton(onTap: _pressAdd, active: addActive),
                    for (final tab in kNavDestinations.skip(2))
                      _NavItem(tab: tab, active: active, onTap: _switchTab),
                  ],
                ),
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
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = tab.icon;
    final label = tab.label;
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.mutedSmall.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The orange "+" FAB. Shared with `AppNavRail`, which anchors it at the bottom
/// of the rail rather than the centre of a bar.
class AddNavButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool active;
  const AddNavButton({super.key, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add expense',
      button: true,
      selected: active,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
                color: AppColors.accent.withValues(alpha: active ? 0.55 : 0.45),
                blurRadius: active ? 22 : 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.25),
              width: active ? 2.5 : 1,
            ),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
