import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A frosted-glass surface — the primary card primitive of the redesign.
///
/// Layers a background blur, a translucent body wash (with a soft top sheen),
/// a hairline inner border, and a soft drop shadow. All tones resolve from the
/// active [AppPalette] so the same widget reads correctly in Light and Dark.
///
/// Pass [onTap] to get a Material ripple clipped to the card's radius. Use
/// [strong] for surfaces that sit over busy content and need more legibility
/// (e.g. transaction ledgers).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final bool strong;

  /// Overrides the theme blur sigma. Lower values are cheaper; a few small
  /// cards can afford the default, long lists should dial it down.
  final double? blur;

  /// When false the soft drop shadow is omitted (for cards that already sit on
  /// a shadowed parent, or rows inside a clipped list).
  final bool shadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
    this.onTap,
    this.strong = false,
    this.blur,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final br = BorderRadius.circular(radius);
    final fill = strong ? c.glassFillStrong : c.glassFill;
    final sigma = blur ?? c.glassBlur;

    Widget inner = child;
    if (padding != null) inner = Padding(padding: padding!, child: child);
    if (onTap != null) {
      inner = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: br, onTap: onTap, child: inner),
      );
    }

    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        // Top sheen → body wash gives the surface a lit, dimensional edge.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.alphaBlend(c.glassHighlight, fill), fill],
        ),
        border: Border.all(color: c.glassBorder, width: 0.8),
      ),
      child: inner,
    );

    final glass = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: body,
      ),
    );

    if (!shadow) return glass;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: glass,
    );
  }
}
