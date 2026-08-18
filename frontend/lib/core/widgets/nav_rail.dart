import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'bottom_nav.dart';

/// Vertical navigation for expanded windows (Fold inner, tablets).
///
/// Same destinations, icons and labels as [BottomNav] — see [NavTabChrome] — so
/// folding the device changes where navigation lives, never what it contains.
///
/// The "+" FAB is anchored at the **bottom** of the rail rather than the top.
/// Material puts a rail's FAB up top, but on an 8-inch unfolded display the top
/// corner is out of reach one-handed, and bottom-anchoring keeps the button in
/// roughly the place the compact bar left it.
class AppNavRail extends StatelessWidget {
  static const double width = 84;

  final NavTab active;
  final ValueChanged<NavTab> onTap;
  final VoidCallback onAdd;

  /// When true (companion pane open) the FAB shows a selected ring.
  final bool addActive;

  const AppNavRail({
    super.key,
    required this.active,
    required this.onTap,
    required this.onAdd,
    this.addActive = false,
  });

  void _switchTab(NavTab tab) {
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
            border: Border(right: BorderSide(color: c.glassBorder, width: 0.8)),
          ),
          child: SafeArea(
            right: false,
            // Matches BottomNav: clamp label scaling so a large system font
            // cannot burst the fixed-height destinations.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    for (final tab in kNavDestinations)
                      _RailItem(tab: tab, active: active, onTap: _switchTab),
                    const Spacer(),
                    AddNavButton(onTap: _pressAdd, active: addActive),
                    const SizedBox(height: 20),
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

class _RailItem extends StatelessWidget {
  final NavTab tab;
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  const _RailItem({
    required this.tab,
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
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(tab),
        radius: 34,
        child: SizedBox(
          // Comfortably over the 48dp Android minimum in both axes.
          width: AppNavRail.width,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tab.icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  tab.label,
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
