import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_info.dart';
import 'update_service.dart';

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate();
}

class UpdateAvailable extends UpdateState {
  final UpdateInfo info;
  const UpdateAvailable(this.info);
}

class UpdateDownloading extends UpdateState {
  final UpdateInfo info;
  final double progress;
  const UpdateDownloading(this.info, this.progress);
}

class UpdateReadyToInstall extends UpdateState {
  final UpdateInfo info;
  final String apkPath;
  const UpdateReadyToInstall(this.info, this.apkPath);
}

class UpdateError extends UpdateState {
  final String message;

  /// What we were updating to, when known — lets the UI offer the right retry
  /// (re-download vs. re-install) instead of a dead-end button.
  final UpdateInfo? info;

  /// Set when the APK is already on disk and only the install step failed, so
  /// retry re-opens the installer rather than downloading again.
  final String? apkPath;

  const UpdateError(this.message, {this.info, this.apkPath});
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

class UpdateController extends Notifier<UpdateState> {
  CancelToken? _cancelToken;

  @override
  UpdateState build() => const UpdateIdle();

  Future<void> checkForUpdate() async {
    if (state is UpdateChecking || state is UpdateDownloading) return;
    state = const UpdateChecking();
    try {
      final info = await ref.read(packageInfoProvider.future);
      final result = await ref
          .read(updateServiceProvider)
          .checkForUpdate(info.version);
      state = result == null ? const UpdateUpToDate() : UpdateAvailable(result);
    } catch (e) {
      state = UpdateError(_friendlyError(e));
    }
  }

  Future<void> downloadUpdate() async {
    // Allow starting from a fresh "available" state or retrying after a
    // download error — both know which release they're fetching.
    final info = switch (state) {
      UpdateAvailable(:final info) => info,
      UpdateError(:final info?) => info,
      _ => null,
    };
    if (info == null) return;

    _cancelToken = CancelToken();
    state = UpdateDownloading(info, 0);

    try {
      final path = await ref.read(updateServiceProvider).downloadApk(
        info.downloadUrl,
        onProgress: (p) => state = UpdateDownloading(info, p),
        cancelToken: _cancelToken,
      );
      state = UpdateReadyToInstall(info, path);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = UpdateAvailable(info);
      } else {
        state = UpdateError(
          'Download failed: ${e.message ?? e.type.name}',
          info: info,
        );
      }
    } catch (e) {
      state = UpdateError(_friendlyError(e), info: info);
    }
  }

  Future<void> install() async {
    // Reachable from a ready state, or a retry after an install-launch failure.
    final (info, apkPath) = switch (state) {
      UpdateReadyToInstall(:final info, :final apkPath) => (info, apkPath),
      UpdateError(:final info?, :final apkPath?) => (info, apkPath),
      _ => (null, null),
    };
    if (info == null || apkPath == null) return;

    final result = await OpenFile.open(apkPath);
    if (result.type != ResultType.done) {
      state = UpdateError(
        result.type == ResultType.permissionDenied
            ? 'Allow "Install unknown apps" for Expensy, then try again.'
            : 'Could not open the installer. Please try again.',
        info: info,
        apkPath: apkPath,
      );
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  void reset() => state = const UpdateIdle();
}

final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

String _friendlyError(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet and try again.';
    }
    return 'Network error. Check your internet and try again.';
  }
  return 'Something went wrong. Please try again.';
}
