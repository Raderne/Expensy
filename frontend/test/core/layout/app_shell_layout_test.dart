import 'package:expensy/app/app_shell.dart';
import 'package:expensy/core/cache/http_cache.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:expensy/core/widgets/bottom_nav.dart';
import 'package:expensy/core/widgets/nav_rail.dart';
import 'package:expensy/core/widgets/two_pane.dart';
import 'package:expensy/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

NavTab _tabFor(String location) {
  if (location.startsWith('/transactions')) return NavTab.transactions;
  if (location.startsWith('/profile')) return NavTab.profile;
  return NavTab.home;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required String location,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          active: _tabFor(state.matchedLocation),
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Center(child: Text('DASHBOARD')),
          ),
          GoRoute(
            path: '/transactions',
            builder: (_, _) => const Center(child: Text('TX_LIST')),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Center(child: Text('PROFILE_BODY')),
            routes: [
              GoRoute(
                path: 'goals',
                builder: (_, _) => const Center(child: Text('GOALS_BODY')),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        httpCacheProvider.overrideWithValue(InMemoryHttpCache()),
        outboxProvider.overrideWithValue(InMemoryOutbox()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// A stock Galaxy Z Fold 7 inner display at 420 dpi. Neither orientation
// reaches Material's 840 dp, which is why the app splits at 700.
const _foldInnerPortrait = Size(750, 832);
const _foldInnerLandscape = Size(832, 750);
const _foldCover = Size(420, 940);

void main() {
  testWidgets('compact phone keeps single pane and bottom nav', (tester) async {
    await _pumpShell(tester, size: const Size(400, 800), location: '/');

    expect(find.byType(BottomNav), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);
    expect(find.byType(TwoPane), findsNothing);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.byType(TransactionsScreen), findsNothing);
  });

  testWidgets('Fold cover screen behaves like a phone', (tester) async {
    await _pumpShell(tester, size: _foldCover, location: '/');

    expect(find.byType(BottomNav), findsOneWidget);
    expect(find.byType(TwoPane), findsNothing);
  });

  for (final (name, size) in [
    ('portrait', _foldInnerPortrait),
    ('landscape', _foldInnerLandscape),
  ]) {
    testWidgets('Fold inner display splits and shows the rail ($name)', (
      tester,
    ) async {
      await _pumpShell(tester, size: size, location: '/');

      expect(find.byType(TwoPane), findsOneWidget);
      expect(find.byType(AppNavRail), findsOneWidget);
      // The rail replaces the bar; showing both would be redundant chrome.
      expect(find.byType(BottomNav), findsNothing);
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.byType(TransactionsScreen), findsOneWidget);
    });
  }

  testWidgets('wide but short window stays single column', (tester) async {
    // Phone in landscape: over the width threshold, far under the height one.
    await _pumpShell(tester, size: const Size(915, 412), location: '/');

    expect(find.byType(TwoPane), findsNothing);
    expect(find.byType(BottomNav), findsOneWidget);
  });

  testWidgets('expanded Home pairs Dashboard with Transactions', (
    tester,
  ) async {
    await _pumpShell(tester, size: const Size(900, 1000), location: '/');

    expect(find.byType(TwoPane), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.byType(TransactionsScreen), findsOneWidget);
  });

  testWidgets('rail navigates and keeps the shell intact', (tester) async {
    await _pumpShell(tester, size: _foldInnerPortrait, location: '/');

    await tester.tap(
      find.descendant(of: find.byType(AppNavRail), matching: find.text('List')),
    );
    await tester.pumpAndSettle();

    expect(find.text('TX_LIST'), findsOneWidget);
    expect(find.byType(AppNavRail), findsOneWidget);
  });

  testWidgets('expanded Profile shows empty companion without nested route', (
    tester,
  ) async {
    await _pumpShell(tester, size: const Size(900, 1000), location: '/profile');

    expect(find.byType(TwoPane), findsOneWidget);
    expect(find.text('Choose a setting'), findsOneWidget);
  });

  testWidgets('expanded Profile nested route shows child on the right', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      size: const Size(900, 1000),
      location: '/profile/goals',
    );

    expect(find.byType(TwoPane), findsOneWidget);
    expect(find.text('GOALS_BODY'), findsOneWidget);
  });
}
