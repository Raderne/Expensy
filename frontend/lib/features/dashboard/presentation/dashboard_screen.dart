import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final name = switch (auth.value) {
      AuthAuthenticated(:final user) => user.name,
      _ => 'there',
    };

    final topInset = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HeroGradient(
          padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Good day, $name',
                  style: AppTextStyles.titleL.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phase 02 shell — real cards land in Phase 03.',
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
