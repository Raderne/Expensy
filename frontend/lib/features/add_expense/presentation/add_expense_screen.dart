import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_bar.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FakeStatusBar(),
          const SizedBox(height: 12),
          Text('Add Expense', style: AppTextStyles.titleL),
          const SizedBox(height: 8),
          Text('Numpad lands in Phase 04.', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
