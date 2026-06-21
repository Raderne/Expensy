import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Fills the screen with the theme background and paints a few soft colored
/// glow blobs behind the content — the ambient lighting that makes the glass
/// cards read as frosted panes floating over a deep surface.
///
/// Intensity scales with [AppPalette.ambientOpacity] (full in Dark, dimmed in
/// Light so a bright background doesn't turn muddy). The painter is static and
/// const-friendly, so it costs a single raster layer and no rebuilds.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: c.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AmbientPainter(intensity: c.ambientOpacity),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double intensity;
  const _AmbientPainter({required this.intensity});

  void _blob(Canvas canvas, Size size, Offset center, double radius, Color c) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [c, c.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Blue wash behind the hero / top-left, warm orange to the top-right, and a
    // cool violet pooled lower down — the three accents from the mockups.
    _blob(
      canvas,
      size,
      Offset(w * 0.08, -h * 0.02),
      w * 0.75,
      AppColors.primary.withValues(alpha: 0.22 * intensity),
    );
    _blob(
      canvas,
      size,
      Offset(w * 0.92, h * 0.04),
      w * 0.70,
      AppColors.accent.withValues(alpha: 0.18 * intensity),
    );
    _blob(
      canvas,
      size,
      Offset(w * 0.5, h * 0.62),
      w * 0.85,
      const Color(0xFF7C3AED).withValues(alpha: 0.12 * intensity),
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.intensity != intensity;
}
