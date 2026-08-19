import 'package:expensy/app/app_shell.dart';
import 'package:expensy/core/cache/http_cache.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:expensy/core/widgets/bottom_nav.dart';
import 'package:expensy/core/widgets/nav_rail.dart';
import 'package:expensy/core/widgets/two_pane.dart';
import 'package:expensy/features/add_expense/presentation/add_expense_screen.dart';
import 'package:expensy/features/analytics/presentation/analytics_pane.dart';
import 'package:expensy/features/analytics/presentation/widgets/analytics_header_bar.dart';
import 'package:expensy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expensy/features/dashboard/presentation/widgets/dashboard_header_bar.dart';
import 'package:expensy/features/profile/presentation/profile_settings_pane.dart';
import 'package:expensy/features/profile/presentation/widgets/account_overview_pane.dart';
import 'package:expensy/features/profile/presentation/widgets/profile_header_bar.dart';
import 'package:expensy/features/transactions/presentation/transactions_screen.dart';
import 'package:expensy/features/transactions/presentation/widgets/activity_feed_pane.dart';
import 'package:expensy/features/transactions/presentation/widgets/month_nav.dart';
import 'package:expensy/features/transactions/presentation/widgets/transactions_header_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

NavTab _tabFor(String location) {
  if (location.startsWith('/transactions')) return NavTab.transactions;
  if (location.startsWith('/analytics')) return NavTab.analytics;
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
            path: '/analytics',
            builder: (_, _) => const Center(child: Text('ANALYTICS')),
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
  group('compact stays exactly as it was', () {
    testWidgets('phone keeps the router child, single pane and bottom nav', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(400, 800), location: '/');

      expect(find.byType(BottomNav), findsOneWidget);
      expect(find.byType(AppNavRail), findsNothing);
      expect(find.byType(TwoPane), findsNothing);
      // Compact renders the routed screen itself — the shell composes panes
      // only when expanded.
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.byType(ActivityFeedPane), findsNothing);
      expect(find.byType(DashboardHeaderBar), findsNothing);
    });

    testWidgets('Fold cover screen behaves like a phone', (tester) async {
      await _pumpShell(tester, size: _foldCover, location: '/');

      expect(find.byType(BottomNav), findsOneWidget);
      expect(find.byType(TwoPane), findsNothing);
    });

    testWidgets('wide but short window stays single column', (tester) async {
      // Phone in landscape: over the width threshold, far under the height one.
      await _pumpShell(tester, size: const Size(915, 412), location: '/');

      expect(find.byType(TwoPane), findsNothing);
      expect(find.byType(BottomNav), findsOneWidget);
    });
  });

  group('expanded shell structure', () {
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
      });
    }

    testWidgets('Home is one header over cards + a chrome-free feed', (
      tester,
    ) async {
      await _pumpShell(tester, size: _foldInnerPortrait, location: '/');

      expect(find.byType(DashboardHeaderBar), findsOneWidget);
      expect(find.byType(DashboardCardsPane), findsOneWidget);
      expect(find.byType(ActivityFeedPane), findsOneWidget);

      // The whole point of the redesign: the companion is not a second screen.
      expect(find.byType(TransactionsScreen), findsNothing);
      expect(find.byType(TransactionsHeaderBar), findsNothing);
      expect(find.byType(MonthNav), findsNothing);
    });

    testWidgets('List states the month exactly once', (tester) async {
      await _pumpShell(
        tester,
        size: _foldInnerPortrait,
        location: '/transactions',
      );

      expect(find.byType(TransactionsHeaderBar), findsOneWidget);
      expect(find.byType(MonthNav), findsOneWidget);
      expect(find.byType(TransactionsBody), findsOneWidget);
      // Add Expense is the companion on List.
      expect(find.byType(AddExpenseScreen), findsOneWidget);
    });

    testWidgets('Stats pairs the analytics pane with a filterable feed', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: _foldInnerPortrait,
        location: '/analytics',
      );

      expect(find.byType(AnalyticsHeaderBar), findsOneWidget);
      expect(find.byType(AnalyticsPane), findsOneWidget);
      expect(find.byType(ActivityFeedPane), findsOneWidget);
      // The feed must not bring a second month control with it.
      expect(find.byType(MonthNav), findsNothing);
    });

    testWidgets('Me fills the companion with the account overview', (
      tester,
    ) async {
      await _pumpShell(tester, size: _foldInnerPortrait, location: '/profile');

      expect(find.byType(ProfileHeaderBar), findsOneWidget);
      expect(find.byType(ProfileSettingsPane), findsOneWidget);
      expect(find.byType(AccountOverviewPane), findsOneWidget);
      // The old dead-zone placeholder is gone for good.
      expect(find.text('Choose a setting'), findsNothing);
    });

    testWidgets('Me nested route shows the child instead of the overview', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: _foldInnerPortrait,
        location: '/profile/goals',
      );

      expect(find.text('GOALS_BODY'), findsOneWidget);
      expect(find.byType(AccountOverviewPane), findsNothing);
      expect(find.byType(ProfileSettingsPane), findsOneWidget);
    });

    testWidgets('rail navigates and keeps the shell intact', (tester) async {
      await _pumpShell(tester, size: _foldInnerPortrait, location: '/');

      await tester.tap(
        find.descendant(
          of: find.byType(AppNavRail),
          matching: find.text('List'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsHeaderBar), findsOneWidget);
      expect(find.byType(AppNavRail), findsOneWidget);
    });
  });
}
