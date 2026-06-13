import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'update_info.dart';

const _repo = 'Raderne/Expensy';
const _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';

final updateServiceProvider = Provider<UpdateService>(
  (_) => UpdateService(Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)))),
);

class UpdateService {
  final Dio _dio;

  UpdateService(this._dio);

  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        _apiUrl,
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );
    } on DioException catch (e) {
      // No published release yet → GitHub returns 404. That's "nothing to
      // update to", not an error worth surfacing.
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }

    final data = response.data;
    if (data == null) return null;
    final tag = (data['tag_name'] as String? ?? '').trim();
    final version = tag.startsWith('v') ? tag.substring(1) : tag;

    if (!_isNewer(version, currentVersion)) return null;

    final assets = (data['assets'] as List<dynamic>? ?? []);
    final apkAsset = assets.cast<Map<String, dynamic>>().firstWhere(
      (a) => (a['name'] as String?)?.endsWith('.apk') ?? false,
      orElse: () => const {},
    );
    final downloadUrl = apkAsset['browser_download_url'] as String?;
    if (downloadUrl == null || !_isTrustedHost(downloadUrl)) return null;

    return UpdateInfo(
      version: version,
      tagName: tag,
      releaseNotes: (data['body'] as String? ?? '').trim(),
      downloadUrl: downloadUrl,
      sizeBytes: apkAsset['size'] as int? ?? 0,
    );
  }

  Future<String> downloadApk(
    String url, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/expensy-update.apk';
    await _dio.download(
      url,
      path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    return path;
  }
}

/// Guards against a tampered API response handing us an off-GitHub URL to
/// download and install. `browser_download_url` is always github.com (it
/// 302-redirects to githubusercontent on fetch, which dio follows).
bool _isTrustedHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  return host == 'github.com' ||
      host.endsWith('.github.com') ||
      host.endsWith('.githubusercontent.com');
}

bool _isNewer(String remote, String current) {
  final r = _parseSemver(remote);
  final c = _parseSemver(current);
  for (var i = 0; i < 3; i++) {
    if (r[i] > c[i]) return true;
    if (r[i] < c[i]) return false;
  }
  return false;
}

List<int> _parseSemver(String v) {
  final parts = v.replaceFirst('v', '').split('.');
  return List.generate(
    3,
    (i) => int.tryParse(parts.elementAtOrNull(i) ?? '0') ?? 0,
  );
}
