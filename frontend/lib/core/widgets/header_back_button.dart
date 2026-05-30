import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared header back button. Centralizes the four near-identical
/// `_BackButton` widgets that used to live in each screen so we don't have to
/// audit them individually for accessibility regressions.
///
/// Two variants exist:
///   * [HeaderBackButton.onHero] — translucent white chip for use on the
///     gradient hero (Recurring expenses, Income sources, Profile).
///   * [HeaderBackButton.onSurface] — soft-shadow white chip for use on the
///     light app background (Add Expense).
///
/// The visible chip stays at 34×34 to keep the existing design tokens, but
/// the touch target is extended to 44×44 via the surrounding [SizedBox] so
/// the control meets the WCAG / iOS HIG / Material guidance minimum. The
/// ink splash stays uncontained so it can ride over the visible chip's
/// rounded corners.
class HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final _BackButtonStyle _style;
  final String semanticLabel;

  const HeaderBackButton.onHero({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Back',
  }) : _style = _BackButtonStyle.hero;

  const HeaderBackButton.onSurface({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Back',
  }) : _style = _BackButtonStyle.surface;

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (_style) {
      _BackButtonStyle.hero => Colors.white,
      _BackButtonStyle.surface => AppColors.ink,
    };
    final chipColor = switch (_style) {
      _BackButtonStyle.hero => Colors.white.withValues(alpha: 0.16),
      _BackButtonStyle.surface => AppColors.surface,
    };
    final radius = _style == _BackButtonStyle.surface ? 10.0 : 11.0;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: onTap,
            radius: 24,
            containedInkWell: false,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: _style == _BackButtonStyle.surface
                      ? const [
                          BoxShadow(
                            color: Color(0x17000000),
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _BackButtonStyle { hero, surface }
