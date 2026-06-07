import 'package:flutter/material.dart';

import 'hero_gradient.dart';

/// A pinned sliver that shows the full blue [expanded] hero and smoothly
/// cross-fades to a compact [collapsed] bar as the user scrolls down.
///
/// The two children fade across offset ranges (expanded gone by ~60% scroll,
/// collapsed appearing only after ~50%) so they never sit at a muddy 50/50 —
/// keeping the transition smooth rather than jarring. The shared
/// [HeroGradient.decoration] background (rounded bottom) stays put throughout.
class SliverCollapsingHero extends StatelessWidget {
  /// Height of the pinned bar (include the top safe-area inset).
  final double minHeight;

  /// Fully-expanded height (include the top safe-area inset).
  final double maxHeight;

  /// Full hero content, shown when expanded. Bottom-aligned so it slides up
  /// under the pinned bar as it shrinks.
  final Widget expanded;

  /// Compact bar content, shown when collapsed. Laid out in the top [minHeight].
  final Widget collapsed;

  const SliverCollapsingHero({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.expanded,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CollapsingHeroDelegate(
        minHeight: minHeight,
        maxHeight: maxHeight,
        expanded: expanded,
        collapsed: collapsed,
      ),
    );
  }
}

class _CollapsingHeroDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget expanded;
  final Widget collapsed;

  _CollapsingHeroDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.expanded,
    required this.collapsed,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = (maxHeight - minHeight).clamp(1.0, double.infinity);
    final progress = (shrinkOffset / range).clamp(0.0, 1.0);

    final expandedOpacity = (1 - progress * 1.6).clamp(0.0, 1.0);
    final collapsedOpacity = ((progress - 0.5) * 2).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: HeroGradient.decoration,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Expanded hero — bottom-aligned so it tucks up under the bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: expandedOpacity == 0,
              child: Opacity(opacity: expandedOpacity, child: expanded),
            ),
          ),
          // Collapsed bar — pinned to the top within minHeight.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: minHeight,
            child: IgnorePointer(
              ignoring: collapsedOpacity == 0,
              child: Opacity(opacity: collapsedOpacity, child: collapsed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CollapsingHeroDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        expanded != oldDelegate.expanded ||
        collapsed != oldDelegate.collapsed;
  }
}
