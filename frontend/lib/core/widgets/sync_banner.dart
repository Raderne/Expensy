import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_status.dart';
import '../theme/app_colors.dart';

/// A thin, self-hiding status bar reflecting connectivity + the outbox. Mounted
/// app-wide via `MaterialApp.router`'s builder; collapses to nothing when there's
/// nothing to report so it never shifts layout in the steady state.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final view = _resolve(status);
    if (view == null) return const SizedBox.shrink();

    return Material(
      color: view.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (view.spinner)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(view.foreground),
                  ),
                )
              else
                Icon(view.icon, size: 15, color: view.foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  view.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: view.foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Priority: failures > waking > syncing/pending > offline > clear.
  _BannerView? _resolve(SyncStatus s) {
    if (s.failedCount > 0) {
      return _BannerView(
        label:
            "${_plural(s.failedCount, 'change', 'changes')} couldn't sync — will retry",
        icon: Icons.error_outline_rounded,
        background: AppColors.dangerLight,
        foreground: AppColors.dangerInk,
      );
    }
    if (s.connection == SyncConnection.waking) {
      return _BannerView(
        label: 'Waking server up…',
        background: AppColors.primaryLight,
        foreground: AppColors.primaryInk,
        spinner: true,
      );
    }
    if (s.syncing ||
        (s.connection == SyncConnection.online && s.pendingCount > 0)) {
      return _BannerView(
        label: s.pendingCount > 0
            ? 'Syncing ${_plural(s.pendingCount, 'change', 'changes')}…'
            : 'Syncing…',
        background: AppColors.primaryLight,
        foreground: AppColors.primaryInk,
        spinner: true,
      );
    }
    if (s.connection == SyncConnection.offline) {
      return _BannerView(
        label: s.pendingCount > 0
            ? "Offline — ${_plural(s.pendingCount, 'change', 'changes')} will sync when you're back"
            : "You're offline",
        icon: Icons.cloud_off_rounded,
        background: AppColors.surfaceAlt,
        foreground: AppColors.inkMid,
      );
    }
    return null;
  }

  static String _plural(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';
}

class _BannerView {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool spinner;

  _BannerView({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon = Icons.sync_rounded,
    this.spinner = false,
  });
}
