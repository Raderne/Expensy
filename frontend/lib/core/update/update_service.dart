import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'update_info.dart';

const _repo = 'Raderne/Expensy';
const _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';
const _apkFileName = 'expensy-update.apk';

final updateServiceProvider = Provider<UpdateService>(
  (_) => UpdateService(
    Dio(BaseOptions(connectTimeout: const Duration(seconds: 10))),
  ),
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

    final assets = (data['assets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final apkAsset = assets.firstWhere(
      (a) => (a['name'] as String?)?.endsWith('.apk') ?? false,
      orElse: () => const {},
    );
    final downloadUrl = apkAsset['browser_download_url'] as String?;
    if (downloadUrl == null || !_isTrustedHost(downloadUrl)) return null;

    final (expectedSha256, checksumUrl) = _resolveChecksumSource(
      assets,
      apkAsset,
    );

    return UpdateInfo(
      version: version,
      tagName: tag,
      releaseNotes: (data['body'] as String? ?? '').trim(),
      downloadUrl: downloadUrl,
      sizeBytes: apkAsset['size'] as int? ?? 0,
      expectedSha256: expectedSha256,
      checksumUrl: checksumUrl,
    );
  }

  Future<String> downloadApk(
    String url, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$_apkFileName';
    await _dio.download(
      url,
      path,
      cancelToken: cancelToken,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    return path;
  }

  /// Verifies the downloaded APK against a published SHA-256.
  ///
  /// Returns `true` when it matches, `false` on mismatch, and `null` when no
  /// checksum is available — in which case the caller proceeds (best-effort;
  /// Android's install-time signature check is the hard integrity guarantee).
  Future<bool?> verifyApk(String path, UpdateInfo info) async {
    final expected = await _resolveExpectedHash(info);
    if (expected == null || expected.isEmpty) return null;
    final actual = await _sha256OfFile(path);
    return actual.toLowerCase() == expected.toLowerCase();
  }

  /// Best-effort removal of the downloaded APK from the temp dir. Called after
  /// a cancel/error and before a fresh download so partial files never linger.
  Future<void> deleteDownloadedApk() async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$_apkFileName');
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<String?> _resolveExpectedHash(UpdateInfo info) async {
    final inline = info.expectedSha256;
    if (inline != null && inline.isNotEmpty) return inline;

    final url = info.checksumUrl;
    if (url == null) return null;
    final resp = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final body = resp.data?.trim();
    if (body == null || body.isEmpty) return null;
    // `.sha256` files are typically "<hex>  <filename>"; take the first token.
    return body.split(RegExp(r'\s+')).first;
  }

  Future<String> _sha256OfFile(String path) async {
    final sink = _DigestSink();
    final converter = sha256.startChunkedConversion(sink);
    await for (final chunk in File(path).openRead()) {
      converter.add(chunk);
    }
    converter.close();
    return sink.value!.toString();
  }
}

/// Picks the checksum source for the APK: GitHub's inline asset `digest`
/// (`"sha256:<hex>"`) if present, else a sibling `<apk>.sha256` asset.
(String?, String?) _resolveChecksumSource(
  List<Map<String, dynamic>> assets,
  Map<String, dynamic> apkAsset,
) {
  final digest = apkAsset['digest'] as String?;
  if (digest != null && digest.startsWith('sha256:')) {
    return (digest.substring('sha256:'.length), null);
  }

  final apkName = apkAsset['name'] as String?;
  if (apkName != null) {
    final shaAsset = assets.firstWhere(
      (a) => (a['name'] as String?) == '$apkName.sha256',
      orElse: () => const {},
    );
    final url = shaAsset['browser_download_url'] as String?;
    if (url != null && _isTrustedHost(url)) return (null, url);
  }
  return (null, null);
}

/// Minimal one-shot [Sink] that captures the final [Digest] from a streamed
/// hash, avoiding a dependency on `package:convert`'s `AccumulatorSink`.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
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
