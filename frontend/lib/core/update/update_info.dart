class UpdateInfo {
  final String version;
  final String tagName;
  final String releaseNotes;
  final String downloadUrl;
  final int sizeBytes;

  /// SHA-256 of the APK as a lowercase hex string (no `sha256:` prefix), taken
  /// from the GitHub asset's `digest` field when present. Null when GitHub
  /// publishes no inline digest.
  final String? expectedSha256;

  /// URL of a sibling `<apk>.sha256` release asset, used as a fallback source
  /// for the checksum when there's no inline [expectedSha256]. Null when no
  /// such asset exists.
  final String? checksumUrl;

  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sizeBytes,
    this.expectedSha256,
    this.checksumUrl,
  });

  String get sizeMb => '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
