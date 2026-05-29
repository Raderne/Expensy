import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 4x3 numpad. Layout: 1-9, then [. 0 ⌫]. ⌫ uses blueLight bg + blue text.
class Numpad extends StatelessWidget {
  final ValueChanged<int> onDigit;
  final VoidCallback onDot;
  final VoidCallback onBackspace;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onDot,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 3,
      crossAxisSpacing: 7,
      mainAxisSpacing: 7,
      childAspectRatio: 2.6,
      children: [
        for (var n = 1; n <= 9; n++) _Key.digit(n: n, onTap: () => _tapDigit(n)),
        _Key.dot(onTap: _tapDot),
        _Key.digit(n: 0, onTap: () => _tapDigit(0)),
        _Key.backspace(onTap: _tapBackspace),
      ],
    );
  }

  void _tapDigit(int n) {
    HapticFeedback.lightImpact();
    onDigit(n);
  }

  void _tapDot() {
    HapticFeedback.lightImpact();
    onDot();
  }

  void _tapBackspace() {
    HapticFeedback.lightImpact();
    onBackspace();
  }
}

class _Key extends StatelessWidget {
  final String label;
  final bool isBackspace;
  final VoidCallback onTap;

  const _Key._({required this.label, required this.onTap, this.isBackspace = false});

  factory _Key.digit({required int n, required VoidCallback onTap}) =>
      _Key._(label: '$n', onTap: onTap);
  factory _Key.dot({required VoidCallback onTap}) =>
      _Key._(label: '.', onTap: onTap);
  factory _Key.backspace({required VoidCallback onTap}) =>
      _Key._(label: '⌫', onTap: onTap, isBackspace: true);

  @override
  Widget build(BuildContext context) {
    final bg = isBackspace ? AppColors.primaryLight : AppColors.surface;
    final fg = isBackspace ? AppColors.primary : AppColors.ink;
    final fontSize = isBackspace ? 16.0 : 18.0;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000C22),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: fontSize,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
