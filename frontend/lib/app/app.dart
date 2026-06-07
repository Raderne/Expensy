import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets_home/home_widget_service.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import 'router.dart';

class ExpensyApp extends ConsumerStatefulWidget {
  const ExpensyApp({super.key});

  @override
  ConsumerState<ExpensyApp> createState() => _ExpensyAppState();
}

class _ExpensyAppState extends ConsumerState<ExpensyApp> {
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    _initHomeWidgetDeepLinks();
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
    return MaterialApp.router(
      title: 'Expensy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
