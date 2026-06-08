import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../application/pending_occurrences_controller.dart';
import '../application/postponed_occurrences_controller.dart';
import '../data/recurring_confirmations_repository.dart';
import '../domain/postponed_info.dart';

/// Edit-sheet section that surfaces a rule's currently-postponed cycle and lets
/// the user move it to another future day or restore it to the original
/// scheduled day. Postpone/reset are occurrence-scoped mutations applied
/// immediately — independent of the rule's Save button. Renders nothing once the
/// cycle has been restored.
class PostponedCycleSection extends ConsumerStatefulWidget {
  final PostponedInfo initial;

  /// Called after a successful change so the parent can refresh its rule list.
  final VoidCallback onChanged;

  const PostponedCycleSection({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  ConsumerState<PostponedCycleSection> createState() =>
      _PostponedCycleSectionState();
}

class _PostponedCycleSectionState extends ConsumerState<PostponedCycleSection> {
  late PostponedInfo? _current = widget.initial;
  bool _busy = false;

  Future<void> _changeDate() async {
    final occ = _current;
    if (occ == null || _busy) return;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final initial = occ.dueAt.isAfter(tomorrow) ? occ.dueAt : tomorrow;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 2, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final target = DateTime(picked.year, picked.month, picked.day);
    await _run(
      () => ref
          .read(recurringConfirmationsRepositoryProvider)
          .postpone(occ.id, target),
      onSuccess: () => setState(
        () => _current = PostponedInfo(
          id: occ.id,
          scheduledFor: occ.scheduledFor,
          dueAt: target,
        ),
      ),
      message: 'Cycle moved to ${DateFormat('MMM d').format(target)}',
    );
  }

  Future<void> _restore() async {
    final occ = _current;
    if (occ == null || _busy) return;
    await _run(
      () => ref.read(recurringConfirmationsRepositoryProvider).reset(occ.id),
      onSuccess: () => setState(() => _current = null),
      message: 'Restored to the scheduled day',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required VoidCallback onSuccess,
    required String message,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      HapticFeedback.selectionClick();
      onSuccess();
      ref.invalidate(pendingOccurrencesControllerProvider);
      ref.invalidate(postponedOccurrencesControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.primary),
        );
      }
    } on RecurringConfirmationsApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update. Try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final occ = _current;
    if (occ == null) return const SizedBox.shrink();

    final dueLabel = DateFormat('EEE, MMM d').format(occ.dueAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'This cycle',
          style: AppTextStyles.muted.copyWith(
            fontSize: 12,
            color: AppColors.inkMid,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent, width: 1.0),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Postponed to $dueLabel',
                        style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 1),
                    Text(
                      'The recurring day is unchanged.',
                      style: AppTextStyles.muted.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else ...[
                TextButton(
                  onPressed: _changeDate,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Change',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _restore,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Restore',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.inkMid,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
