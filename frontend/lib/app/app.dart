import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/theme/app_colors.dart';
import '../core/update/auto_update.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets_home/home_widget_service.dart';
import '../core/widgets_home/widget_appearance_service.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/settings/application/theme_controller.dart';
import '../features/settings/application/widget_appearance_controller.dart';
import '../features/settings/domain/app_theme_mode.dart';
import 'router.dart';

class ExpensyApp extends ConsumerStatefulWidget {
  const ExpensyApp({super.key});

  @override
  ConsumerState<ExpensyApp> createState() => _ExpensyAppState();
}

class _ExpensyAppState extends ConsumerState<ExpensyApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initHomeWidgetDeepLinks();
    // Push saved widget appearance to the home screen once mounted, so the
    // widgets reflect persisted settings even after an app reinstall.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        WidgetAppearanceService.applyAll(ref.read(widgetAppearanceProvider)),
      );
    });
  }

  /// Rebuild when the phone toggles light/dark so System mode re-resolves the
  /// active palette (see [build]).
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget: result handled by screen-level listeners (dashboard,
      // profile). Interval-gated to at most once every 7 days.
      maybeAutoCheckOnResume(ref);
    }
  }

  /// Handle taps on the home-screen widgets: the warm-start stream while the app
  /// is running, plus the cold-start URI captured when the app was launched from
  /// a widget.
  Future<void> _initHomeWidgetDeepLinks() async {
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launchUri != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleWidgetUri(launchUri),
      );
    }
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final router = ref.read(routerProvider);
    switch (uri.host) {
      case 'add':
        router.push('/add');
      case 'transactions':
        router.go('/transactions');
      default:
        router.go('/');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Push the latest dashboard snapshot to the home-screen widgets whenever it
    // changes — this covers app launch, SWR background refresh, and any mutation
    // that invalidates the dashboard (add expense, delete, budget change). On
    // logout the dashboard rebuilds to its empty state, which clears the widgets.
    ref.listen<AsyncValue<DashboardState>>(dashboardControllerProvider, (
      _,
      next,
    ) {
      final data = next.asData?.value;
      if (data != null) unawaited(HomeWidgetService.sync(data));
    });

    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);

    // Keep the globally-active palette in sync with the brightness MaterialApp
    // will actually resolve, BEFORE descendants build and read `AppColors.x`.
    // System mode follows the phone; Dark/AMOLED are explicit dark choices.
    final systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppColors.active = switch (mode) {
      AppThemeMode.light => AppPalette.light,
      AppThemeMode.dark => AppPalette.dark,
      AppThemeMode.amoled => AppPalette.amoled,
      AppThemeMode.system => systemBrightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light,
    };

    return MaterialApp.router(
      title: 'Expensy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: mode == AppThemeMode.amoled
          ? AppTheme.amoled()
          : AppTheme.dark(),
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.amoled => ThemeMode.dark,
      },
      routerConfig: router,
    );
  }
}
