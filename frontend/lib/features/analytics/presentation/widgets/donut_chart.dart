import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/analytics_breakdown.dart';

/// Mirrors the SVG donut in `design/Expensy.html`:
/// radius 50, stroke width 13, gap 2.5 between segments, starting at -90°.
/// Animates each segment's sweep from 0 to its target on first paint.
class DonutChart extends StatefulWidget {
  final AnalyticsBreakdown data;
  final double size;

  const DonutChart({super.key, required this.data, this.size = 180});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, _) => CustomPaint(
          painter: _DonutPainter(
            items: widget.data.items,
            progress: _progress.value,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.mutedSmall.copyWith(
                    color: AppColors.inkMid,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCurrency(widget.data.total),
                  style: AppTextStyles.titleM.copyWith(
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(double v) {
  final whole = v.toStringAsFixed(0);
  // Group thousands for readability without pulling in the intl package twice.
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i != 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '\$$buf';
}

class _DonutPainter extends CustomPainter {
  final List<BreakdownItem> items;
  final double progress;

  static const _radius = 50.0;
  static const _stroke = 13.0;
  static const _gapDegrees = 2.0; // small visual gap between segments

  _DonutPainter({required this.items, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Scale the design constants (R=50, SW=13) to fit `size`.
    final scale = (size.shortestSide / 2) / (_radius + _stroke / 2);
    final radius = _radius * scale;
    final stroke = _stroke * scale;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Base ring (always visible — keeps the shape even when empty).
    final base = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, base);

    if (items.isEmpty) return;

    // The visible arcs must sum to 360° minus N*gap. We allocate each segment's
    // arc length proportionally to its pct, then leave the gap at its end.
    final gapRad = _gapDegrees * math.pi / 180;
    final totalGaps = items.length * gapRad;
    final availableSweep = 2 * math.pi - totalGaps;

    var startAngle = -math.pi / 2; // start at 12 o'clock
    for (final item in items) {
      final fullSweep = availableSweep * item.pct;
      final sweep = fullSweep * progress;
      if (sweep > 0) {
        final paint = Paint()
          ..color = item.colorValue
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, sweep, false, paint);
      }
      startAngle += fullSweep + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.items != items;
}
