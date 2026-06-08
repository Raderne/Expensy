import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'config/env.dart';
import 'core/cache/http_cache.dart';
import 'features/settings/data/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('Expensy API_BASE_URL=${Env.apiBaseUrl}');
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Open the SWR cache before the first frame so controllers can read it
  // synchronously. Falls back to in-memory if Hive can't initialize so the
  // app still launches in restricted environments (e.g. some test harnesses).
  HttpCache cache;
  try {
    cache = await HiveHttpCache.open();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('HiveHttpCache.open failed ($e); falling back to in-memory');
    }
    cache = InMemoryHttpCache();
  }

  // Same deal for app preferences (theme mode, widget appearance) — read
  // synchronously on launch so there's no light-mode flash before the saved
  // theme applies.
  SettingsStore settings;
  try {
    settings = await HiveSettingsStore.open();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('HiveSettingsStore.open failed ($e); falling back to in-memory');
    }
    settings = InMemorySettingsStore();
  }

  runApp(
    ProviderScope(
      overrides: [
        httpCacheProvider.overrideWithValue(cache),
        settingsStoreProvider.overrideWithValue(settings),
      ],
      child: const ExpensyApp(),
    ),
  );
}
