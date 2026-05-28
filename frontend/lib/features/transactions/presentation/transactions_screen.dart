import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transactions', style: AppTextStyles.titleL),
          const SizedBox(height: 8),
          Text('List + month nav land in Phase 05.', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
