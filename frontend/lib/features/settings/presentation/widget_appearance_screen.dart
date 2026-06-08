import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../../core/widgets/hero_gradient.dart';
import '../application/widget_appearance_controller.dart';
import '../domain/widget_appearance.dart';

/// Per-widget-type background customization (Transparent | Solid, opacity, and
/// Dark | Light | Match-phone color). Settings apply to all instances of each
/// widget type and are pushed to the home screen as the user edits.
class WidgetAppearanceScreen extends ConsumerWidget {
  const WidgetAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final config = ref.watch(widgetAppearanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeroGradient(
              padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      HeaderBackButton.onHero(onTap: () => context.pop()),
                      const Spacer(),
                      Text(
                        'Widgets',
                        style: AppTextStyles.titleM.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Style each home-screen widget. Changes apply to all copies of that widget.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            sliver: SliverList.list(
              children: [
                for (final type in WidgetType.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _WidgetCard(
                      type: type,
                      appearance: config[type] ?? WidgetAppearance.defaults,
                      onChanged: (a) => ref
                          .read(widgetAppearanceProvider.notifier)
                          .set(type, a),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  final WidgetType type;
  final WidgetAppearance appearance;
  final ValueChanged<WidgetAppearance> onChanged;

  const _WidgetCard({
    required this.type,
    required this.appearance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final transparent = appearance.bg == WidgetBgStyle.transparent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(type.icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                type.label,
                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WidgetPreview(appearance: appearance, type: type),
          const SizedBox(height: 16),

          _FieldLabel('Background'),
          const SizedBox(height: 8),
          _Segmented<WidgetBgStyle>(
            value: appearance.bg,
            options: const {
              WidgetBgStyle.transparent: 'Transparent',
              WidgetBgStyle.solid: 'Solid',
            },
            onChanged: (v) => onChanged(appearance.copyWith(bg: v)),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Opacity'),
          Opacity(
            opacity: transparent ? 0.4 : 1,
            child: Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.inkFaint,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.12),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: appearance.opacity.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: transparent
                          ? null
                          : (v) => onChanged(
                              appearance.copyWith(opacity: v.round()),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${appearance.opacity}%',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.inkMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Color'),
          const SizedBox(height: 8),
          _Segmented<WidgetColorMode>(
            value: appearance.color,
            options: const {
              WidgetColorMode.dark: 'Dark',
              WidgetColorMode.light: 'Light',
              WidgetColorMode.matchPhone: 'Match phone',
            },
            onChanged: (v) => onChanged(appearance.copyWith(color: v)),
          ),
        ],
      ),
    );
  }
}

/// A faithful-enough preview of the widget background over a wallpaper-like
/// strip, so transparency and color read at a glance.
class _WidgetPreview extends StatelessWidget {
  final WidgetAppearance appearance;
  final WidgetType type;

  const _WidgetPreview({required this.appearance, required this.type});

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context, appearance.color);
    final base = dark ? const Color(0xFF0B0E16) : const Color(0xFFFFFFFF);
    final alpha = appearance.bg == WidgetBgStyle.transparent
        ? 0.0
        : appearance.opacity / 100;
    final fill = base.withValues(alpha: alpha);
    final ink = dark ? const Color(0xFFF2F5FC) : const Color(0xFF0C1530);
    final muted = dark ? const Color(0xFF8A93AD) : const Color(0xFF7A8AAA);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Faux wallpaper so transparency is visible.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF334155), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          Container(
            height: 78,
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.label,
                  style: AppTextStyles.labelStrong.copyWith(color: ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Preview',
                  style: AppTextStyles.muted.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDark(BuildContext context, WidgetColorMode mode) => switch (mode) {
    WidgetColorMode.dark => true,
    WidgetColorMode.light => false,
    WidgetColorMode.matchPhone =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };
}

class _Segmented<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (entry.key != value) {
                    HapticFeedback.selectionClick();
                    onChanged(entry.key);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: entry.key == value
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value,
                    style: AppTextStyles.label.copyWith(
                      color: entry.key == value
                          ? Colors.white
                          : AppColors.inkMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.muted.copyWith(
        fontSize: 11.5,
        color: AppColors.inkMid,
        letterSpacing: 0.2,
      ),
    );
  }
}
