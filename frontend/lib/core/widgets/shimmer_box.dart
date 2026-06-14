import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Drives a single [AnimationController] that all [ShimmerBox] descendants
/// share — so every box animates in perfect sync with zero extra overhead.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(animation: _ctrl, child: widget.child);
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerScope old) => animation != old.animation;
}

/// A rounded rectangle placeholder that sweeps a soft highlight from left to
/// right using the nearest [Shimmer] ancestor's animation.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
    this.baseColor,
    this.shineColor,
  });

  final double height;
  final double? width;
  final double radius;

  /// Defaults to the theme's shimmer tones when null.
  final Color? baseColor;
  final Color? shineColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = this.baseColor ?? AppColors.shimmerBase;
    final shineColor = this.shineColor ?? AppColors.shimmerHighlight;
    final animation = Shimmer.of(context);
    if (animation == null) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value;
        return Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-3 + 4 * t, 0),
              end: Alignment(-1 + 4 * t, 0),
              colors: [baseColor, shineColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}
