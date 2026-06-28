import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../application/goal_estimate_controller.dart';
import '../../data/goals_repository.dart';
import '../../domain/goal.dart';
import '../../domain/goal_estimate.dart';

/// Bottom sheet showing the AI time-to-reach estimate for a single [Goal].
/// Fetched lazily through `goalEstimateControllerProvider(goal.id)`.
///
/// Draggable: it rests at [_restSize], expands up to [_maxSize] (almost full
/// screen) when swiped up, and dismisses when dragged below [_minSize].
class GoalEstimateSheet extends ConsumerStatefulWidget {
  final Goal goal;
  const GoalEstimateSheet({super.key, required this.goal});

  /// Opens the estimate as a draggable, expandable modal sheet.
  static Future<void> show(BuildContext context, Goal goal) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      // DraggableScrollableSheet owns the drag gesture (expand + dismiss), so
      // the modal's own drag-to-dismiss must be off to avoid the two fighting.
      enableDrag: false,
      builder: (_) => GoalEstimateSheet(goal: goal),
    );
  }

  @override
  ConsumerState<GoalEstimateSheet> createState() => _GoalEstimateSheetState();
}

class _GoalEstimateSheetState extends ConsumerState<GoalEstimateSheet> {
  // Fractions of screen height: resting, dismiss threshold, and expanded.
  static const double _restSize = 0.6;
  static const double _minSize = 0.5;
  static const double _maxSize = 0.92;

  // Guards against firing pop more than once while the sheet hovers at min.
  bool _dismissing = false;

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final estimateAsync = ref.watch(goalEstimateControllerProvider(goal.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _restSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_restSize, _maxSize],
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            // Dragged below the resting point — treat as swipe-to-dismiss.
            if (!_dismissing && n.extent <= n.minExtent + 0.001) {
              _dismissing = true;
              Navigator.of(context).maybePop();
            }
            return false;
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.scrim,
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              // The whole surface scrolls through [scrollController], so a drag
              // anywhere expands the sheet (and scrolls content once expanded).
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.inkFaint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Header(
                      goalName: goal.name,
                      busy: estimateAsync.isLoading,
                      onRefresh: () => ref
                          .read(goalEstimateControllerProvider(goal.id).notifier)
                          .refresh(),
                    ),
                    const SizedBox(height: 18),
                    estimateAsync.when(
                      loading: () => const _LoadingState(),
                      error: (err, _) => _ErrorState(
                        error: err,
                        onRetry: () => ref
                            .read(
                              goalEstimateControllerProvider(goal.id).notifier,
                            )
                            .refresh(),
                      ),
                      data: (estimate) =>
                          _EstimateContent(goal: goal, estimate: estimate),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String goalName;
  final bool busy;
  final VoidCallback onRefresh;

  const _Header({
    required this.goalName,
    required this.busy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 19,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI estimate', style: AppTextStyles.titleM),
              Text(
                goalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.muted,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: busy ? null : onRefresh,
          tooltip: 'Recalculate',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: busy ? AppColors.inkFaint : AppColors.inkLight,
          ),
        ),
      ],
    );
  }
}

class _EstimateContent extends StatelessWidget {
  final Goal goal;
  final GoalEstimate estimate;

  const _EstimateContent({required this.goal, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final reachable = estimate.reachable && estimate.estimatedMonths != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero estimate.
        Text(
          reachable
              ? _humanMonths(estimate.estimatedMonths!)
              : 'Beyond reach',
          style: AppTextStyles.titleL.copyWith(
            fontSize: 30,
            letterSpacing: -0.5,
            color: reachable ? AppColors.ink : AppColors.accentInk,
          ),
        ),
        const SizedBox(height: 2),
        if (reachable && estimate.estimatedDate != null)
          Text(
            'On track for ${DateFormat('MMM yyyy').format(estimate.estimatedDate!)}',
            style: AppTextStyles.muted,
          )
        else
          Text(
            'at your current saving pace',
            style: AppTextStyles.muted,
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _confidenceChip(estimate.confidence),
            if (reachable) _scheduleChip(),
            if (estimate.monthlyNetSavings > 0)
              _Pill(
                label: '${money.format(estimate.monthlyNetSavings)}/mo saved',
                color: AppColors.inkLight,
                bg: AppColors.surfaceAlt,
                icon: Icons.trending_up_rounded,
              ),
          ],
        ),
        if (estimate.summary.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(estimate.summary, style: AppTextStyles.body.copyWith(height: 1.4)),
        ],
        if (estimate.tips.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Ways to get there faster', style: AppTextStyles.titleS),
          const SizedBox(height: 10),
          ...estimate.tips.map(_tipRow),
        ],
        const SizedBox(height: 14),
        Text(
          'AI-generated · for guidance only',
          style: AppTextStyles.mutedSmall,
        ),
      ],
    );
  }

  // On-track vs the goal's own target date, when one is set.
  Widget _scheduleChip() {
    final target = goal.targetDate;
    final eta = estimate.estimatedDate;
    if (target == null || eta == null) return const SizedBox.shrink();
    final onTrack = !eta.isAfter(target);
    return _Pill(
      label: onTrack ? 'Meets your target' : 'Behind your target',
      color: onTrack ? AppColors.successInk : AppColors.dangerInk,
      bg: onTrack ? AppColors.successLight : AppColors.dangerLight,
      icon: onTrack
          ? Icons.check_circle_outline_rounded
          : Icons.schedule_rounded,
    );
  }

  Widget _confidenceChip(String level) {
    final (Color ink, Color bg) = switch (level) {
      'high' => (AppColors.successInk, AppColors.successLight),
      'medium' => (AppColors.primaryInk, AppColors.primaryLight),
      _ => (AppColors.accentInk, AppColors.accentLight),
    };
    return _Pill(
      label: '$level confidence',
      color: ink,
      bg: bg,
      icon: Icons.insights_rounded,
    );
  }

  Widget _tipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip, style: AppTextStyles.body.copyWith(height: 1.35)),
          ),
        ],
      ),
    );
  }

  static String _humanMonths(int m) {
    if (m <= 0) return 'This month';
    if (m < 12) return '~$m ${m == 1 ? 'month' : 'months'}';
    final years = m ~/ 12;
    final rem = m % 12;
    final yPart = '$years ${years == 1 ? 'yr' : 'yrs'}';
    return rem == 0 ? '~$yPart' : '~$yPart $rem mo';
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const _Pill({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelStrong.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 30, width: 160, radius: 8),
          SizedBox(height: 10),
          ShimmerBox(height: 14, width: 200),
          SizedBox(height: 16),
          ShimmerBox(height: 28, width: 240, radius: 10),
          SizedBox(height: 18),
          ShimmerBox(height: 14),
          SizedBox(height: 8),
          ShimmerBox(height: 14, width: 260),
          SizedBox(height: 18),
          ShimmerBox(height: 14, width: 140),
          SizedBox(height: 10),
          ShimmerBox(height: 14),
          SizedBox(height: 8),
          ShimmerBox(height: 14, width: 220),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final code = error is GoalsApiException
        ? (error as GoalsApiException).code
        : null;

    final (IconData icon, String title, String body, bool canRetry) =
        switch (code) {
          'INSUFFICIENT_DATA' => (
            Icons.receipt_long_rounded,
            'Not enough history yet',
            'Add a few transactions so we can learn your spending and estimate this goal.',
            false,
          ),
          'AI_UNAVAILABLE' => (
            Icons.cloud_off_rounded,
            'Estimates unavailable',
            'AI estimates are temporarily unavailable. Please try again later.',
            true,
          ),
          _ => (
            Icons.error_outline_rounded,
            'Couldn’t estimate',
            'Something went wrong generating this estimate.',
            true,
          ),
        };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 38, color: AppColors.inkLight),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: AppTextStyles.body),
          if (canRetry) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
