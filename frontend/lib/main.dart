import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'config/env.dart';
import 'core/cache/http_cache.dart';
import 'core/theme/app_colors.dart';

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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.surface,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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

  runApp(
    ProviderScope(
      overrides: [httpCacheProvider.overrideWithValue(cache)],
      child: const ExpensyApp(),
    ),
  );
}
