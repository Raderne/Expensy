import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/simple_markdown.dart';
import 'update_controller.dart';
import 'update_info.dart';

class UpdateSheet extends ConsumerWidget {
  final UpdateInfo info;

  const UpdateSheet({super.key, required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);

    return DecoratedBox(
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Update available', style: AppTextStyles.titleM),
                        const SizedBox(height: 2),
                        Text(
                          'v${info.version}  ·  ${info.sizeMb}',
                          style: AppTextStyles.muted.copyWith(
                            color: AppColors.inkMid,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (info.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  "What's new",
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 12,
                    color: AppColors.inkMid,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: SimpleMarkdown(data: info.releaseNotes),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (state is UpdateDownloading) ...[
                _ProgressSection(state.progress),
                const SizedBox(height: 12),
                _OutlineButton(
                  label: 'Cancel',
                  onTap: () => ref
                      .read(updateControllerProvider.notifier)
                      .cancelDownload(),
                ),
              ] else if (state is UpdateVerifying) ...[
                const _VerifyingSection(),
              ] else if (state is UpdateReadyToInstall) ...[
                _PrimaryButton(
                  label: 'Install now',
                  icon: Icons.download_done_rounded,
                  onTap: () =>
                      ref.read(updateControllerProvider.notifier).install(),
                ),
              ] else ...[
                if (state is UpdateError) ...[
                  Text(
                    state.message,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                // After an install-launch failure the APK is already on disk,
                // so retry the install; otherwise (re)download.
                if (state is UpdateError && state.apkPath != null)
                  _PrimaryButton(
                    label: 'Install now',
                    icon: Icons.download_done_rounded,
                    onTap: () =>
                        ref.read(updateControllerProvider.notifier).install(),
                  )
                else
                  _PrimaryButton(
                    label: state is UpdateError
                        ? 'Retry download'
                        : 'Download update',
                    icon: Icons.download_rounded,
                    onTap: () => ref
                        .read(updateControllerProvider.notifier)
                        .downloadUpdate(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyingSection extends StatelessWidget {
  const _VerifyingSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Verifying download…',
          style: AppTextStyles.label.copyWith(color: AppColors.inkMid),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  const _ProgressSection(this.progress);

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading…',
              style: AppTextStyles.label.copyWith(color: AppColors.inkMid),
            ),
            Text(
              '$pct%',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.primaryLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.27),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelStrong.copyWith(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelStrong.copyWith(
            fontSize: 14,
            color: AppColors.inkMid,
          ),
        ),
      ),
    );
  }
}

/// Shows the update sheet and flags it visible for the duration, so callers
/// (the profile screen) can suppress snackbars the sheet already surfaces.
Future<void> showUpdateSheet(
  BuildContext context,
  WidgetRef ref,
  UpdateInfo info,
) async {
  ref.read(updateSheetVisibleProvider.notifier).set(true);
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (_) => UpdateSheet(info: info),
    );
  } finally {
    ref.read(updateSheetVisibleProvider.notifier).set(false);
  }
}
