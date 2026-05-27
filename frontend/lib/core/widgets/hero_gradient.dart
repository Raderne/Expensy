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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
