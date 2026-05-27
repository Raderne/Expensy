import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Mock iOS-style status bar from the design (time + signal/wifi/battery).
/// Use [light] when rendered over the dark hero gradient.
class FakeStatusBar extends StatelessWidget {
  final bool light;
  const FakeStatusBar({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final color = light ? AppColors.surface : AppColors.ink;
    return SizedBox(
      height: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41', style: AppTextStyles.labelStrong.copyWith(color: color)),
            Row(
              children: [
                Icon(Icons.signal_cellular_4_bar, size: 14, color: color),
                const SizedBox(width: 4),
                Icon(Icons.wifi, size: 14, color: color),
                const SizedBox(width: 4),
                Icon(Icons.battery_full, size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
