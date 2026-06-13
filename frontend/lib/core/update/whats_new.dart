import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'update_controller.dart';

/// One-shot guard: ensures the "What's New" sheet is attempted at most once per
/// app session, so returning to the dashboard doesn't re-trigger it.
final whatsNewCheckedProvider =
    NotifierProvider<BoolFlagNotifier, bool>(BoolFlagNotifier.new);

/// Shows the release notes once, the first time the app runs as the version the
/// in-app updater installed. Notes are written at install time (see
/// [UpdateController.install]); here we read them back, show them, and clear the
/// keys so they never reappear.
///
/// No-ops when: already attempted this session, the running version doesn't
/// match the pending one (install not completed), or no notes were stored.
Future<void> maybeShowWhatsNew(BuildContext context, WidgetRef ref) async {
  if (ref.read(whatsNewCheckedProvider)) return;
  ref.read(whatsNewCheckedProvider.notifier).set(true);

  final store = ref.read(settingsStoreProvider);
  final pendingVersion = store.getString(pendingUpdateVersionKey);
  final notes = store.getString(pendingUpdateNotesKey);
  if (pendingVersion == null || pendingVersion.isEmpty) return;
  if (notes == null || notes.isEmpty) return;

  final current = await ref.read(packageInfoProvider.future);
  // Install hasn't completed yet (user dismissed the system installer); keep the
  // keys and try again on a later launch.
  if (current.version != pendingVersion) return;

  await store.setString(pendingUpdateVersionKey, '');
  await store.setString(pendingUpdateNotesKey, '');

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (_) => _WhatsNewSheet(version: pendingVersion, notes: notes),
  );
}

class _WhatsNewSheet extends StatelessWidget {
  final String version;
  final String notes;

  const _WhatsNewSheet({required this.version, required this.notes});

  @override
  Widget build(BuildContext context) {
    final maxNotesHeight = MediaQuery.sizeOf(context).height * 0.45;

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
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("What's new", style: AppTextStyles.titleM),
                        const SizedBox(height: 2),
                        Text(
                          'v$version',
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
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxNotesHeight),
                child: SingleChildScrollView(
                  child: Text(
                    notes,
                    style: AppTextStyles.body.copyWith(fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _GotItButton(onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _GotItButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GotItButton({required this.onTap});

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
        child: Text(
          'Got it',
          style: AppTextStyles.labelStrong.copyWith(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
