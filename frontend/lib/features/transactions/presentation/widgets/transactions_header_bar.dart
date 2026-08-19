import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/hero_gradient.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../application/month_nav_direction.dart';
import '../../application/transactions_controller.dart';
import 'filters_sheet.dart';
import 'month_nav.dart';

/// Title + filters + month navigator on the blue gradient.
///
/// Used as the compact screen's fixed hero *and* as the expanded shell's
/// full-width destination header. Because it is the one place the month is
/// stated, the panes underneath carry no month control of their own — that
/// duplication is exactly what made the unfolded layout read as two apps.
class TransactionsHeaderBar extends ConsumerWidget {
  const TransactionsHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final async = ref.watch(transactionsViewProvider);
    final state = async.value;

    return DecoratedBox(
      decoration: HeroGradient.decoration,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          pageInsetOf(context),
          topInset + 10,
          pageInsetOf(context),
          18,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Expanded rather than Spacer: in a narrow window or at a large
                // system font the title must give way to the filter button, not
                // push it off the edge.
                Expanded(
                  child: Text(
                    'Transactions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleL.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                if (state != null)
                  _FilterButton(
                    active: state.filters.isActive,
                    onTap: () => showTransactionsFiltersSheet(
                      context,
                      initial: state.filters,
                      onApply: (filters) => ref
                          .read(transactionsControllerProvider.notifier)
                          .applyFilters(filters),
                    ),
                  )
                else
                  const ShimmerBox(height: 38, width: 38, radius: 11),
              ],
            ),
            const SizedBox(height: 16),
            if (state != null)
              MonthNav(
                month: state.month,
                canGoPrev: !state.isAtOldest,
                canGoNext: !state.isAtNewest,
                onPrev: () => _navigate(ref, older: true),
                onNext: () => _navigate(ref, older: false),
                onHero: true,
              )
            else
              const SizedBox(
                height: 40,
                child: Center(
                  child: ShimmerBox(height: 22, width: 148, radius: 6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Records the direction (for the body's slide transition), fires a light
  /// haptic, then triggers the month change.
  void _navigate(WidgetRef ref, {required bool older}) {
    final dir = ref.read(monthNavDirectionProvider.notifier);
    older ? dir.older() : dir.newer();
    HapticFeedback.selectionClick();
    final controller = ref.read(transactionsControllerProvider.notifier);
    older ? controller.previousMonth() : controller.nextMonth();
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Filters, active' : 'Filters',
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(16, 13),
                    painter: _FilterIconPainter(),
                  ),
                ),
                if (active)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    void bar(double x, double y, double w) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, 1.8),
          const Radius.circular(0.9),
        ),
        paint,
      );
    }

    bar(0, 0, 16);
    bar(3, 5.5, 10);
    bar(6, 11, 4);
  }

  @override
  bool shouldRepaint(covariant _FilterIconPainter oldDelegate) => false;
}
