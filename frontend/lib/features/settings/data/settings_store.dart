import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Synchronous key/value store for small app preferences (theme mode, widget
/// appearance). Opened in [main] before the first frame so controllers can read
/// the persisted value synchronously and avoid a light-mode flash on launch.
abstract class SettingsStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

class HiveSettingsStore implements SettingsStore {
  HiveSettingsStore(this._box);

  static const _boxName = 'settings_v1';
  static bool _hiveInitialized = false;

  final Box<String> _box;

  /// Opens the underlying Hive box. Throws if Hive can't initialize — callers
  /// should fall back to [InMemorySettingsStore] in that case.
  static Future<HiveSettingsStore> open() async {
    if (!_hiveInitialized) {
      final dir = await getApplicationSupportDirectory();
      // Safe even if HttpCache already called Hive.init — it just (re)sets the
      // same home path.
      Hive.init(dir.path);
      _hiveInitialized = true;
    }
    final box = await Hive.openBox<String>(_boxName);
    return HiveSettingsStore(box);
  }

  @override
  String? getString(String key) => _box.get(key);

  @override
  Future<void> setString(String key, String value) => _box.put(key, value);
}

/// Fallback used when Hive can't initialize (tests, sandboxed environments).
class InMemorySettingsStore implements SettingsStore {
  final Map<String, String> _store = {};

  @override
  String? getString(String key) => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }
}

/// ISO-8601 timestamp of the last automatic update check.
const lastUpdateCheckKey = 'last_update_check_at';

/// Provider for the singleton store. Override in [main] via `overrideWithValue`
/// with the result of [HiveSettingsStore.open] (or [InMemorySettingsStore] on
/// failure) so controllers can read it synchronously.
final settingsStoreProvider = Provider<SettingsStore>((ref) {
  if (kDebugMode) {
    debugPrint(
      'settingsStoreProvider not overridden; using in-memory fallback.',
    );
  }
  return InMemorySettingsStore();
});
