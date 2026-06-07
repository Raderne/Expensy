import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Top header gradient used by the Dashboard hero.
/// Primary → primaryDark, vertical.
class HeroGradient extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HeroGradient({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  /// Shared so the collapsing-hero sliver paints an identical background.
  static const BoxDecoration decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment(-0.5, -1.0),
      end: Alignment(0.5, 1.0),
      colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF2D5FF5)],
      stops: [0.0, 0.55, 1.0],
    ),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );
  }
}
