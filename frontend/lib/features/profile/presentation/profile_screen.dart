import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/collapsing_hero.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import 'profile_settings_pane.dart';
import 'widgets/profile_header_bar.dart';

/// Compact (phone / folded) Me: collapsing identity hero above the settings
/// list.
///
/// On an expanded window the shell uses [ProfileHeaderBar] as the destination
/// header, [ProfileSettingsPane] as the left pane and either the open setting
/// or `AccountOverviewPane` as the companion.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(authControllerProvider).value) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final topInset = MediaQuery.paddingOf(context).top;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverCollapsingHero(
          minHeight: topInset + 56,
          maxHeight: topInset + 220,
          expanded: ProfileHeroContent(topInset: topInset, user: user),
          collapsed: _ProfileHeroCollapsed(topInset: topInset, name: user.name),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            pageInsetOf(context),
            16,
            pageInsetOf(context),
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: const SliverToBoxAdapter(child: ProfileSettingsList()),
        ),
      ],
    );
  }
}

/// Compact bar shown once the profile hero is scrolled away: full name.
class _ProfileHeroCollapsed extends StatelessWidget {
  final double topInset;
  final String name;

  const _ProfileHeroCollapsed({required this.topInset, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topInset,
        left: heroInsetOf(context),
        right: heroInsetOf(context),
      ),
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleM.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
