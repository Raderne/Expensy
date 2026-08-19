import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/hero_gradient.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/domain/auth_user.dart';

/// Tall centred identity block — the compact screen's expanded hero.
class ProfileHeroContent extends StatelessWidget {
  final double topInset;
  final AuthUser user;

  const ProfileHeroContent({
    super.key,
    required this.topInset,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        heroInsetOf(context),
        topInset + 8,
        heroInsetOf(context),
        24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'Profile',
              style: AppTextStyles.titleM.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          ProfileAvatar(name: user.name),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: AppTextStyles.titleM.copyWith(
              color: Colors.white,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width destination header for the expanded shell.
///
/// The compact hero stacks avatar over name over email because a phone has
/// width to spare and height to fill. Here it is the other way round, so the
/// same three pieces sit in a row and the band costs ~96 dp instead of 220.
class ProfileHeaderBar extends ConsumerWidget {
  const ProfileHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final user = switch (ref.watch(authControllerProvider).value) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    return DecoratedBox(
      decoration: HeroGradient.decoration,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          heroInsetOf(context),
          topInset + 14,
          heroInsetOf(context),
          20,
        ),
        child: Row(
          children: [
            ProfileAvatar(name: user?.name ?? '', size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.name ?? 'Profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleM.copyWith(
                      color: Colors.white,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ProfileAvatar({super.key, required this.name, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppTextStyles.titleM.copyWith(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    if (parts.length == 1) return first;
    final last = parts.last.characters.first.toUpperCase();
    return '$first$last';
  }
}
