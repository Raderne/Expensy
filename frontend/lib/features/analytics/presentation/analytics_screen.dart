import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: AppTextStyles.titleL),
          const SizedBox(height: 8),
          Text('Donut + bars land in Phase 06.', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
