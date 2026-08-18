import 'package:expensy/app/app_shell.dart';
import 'package:expensy/core/cache/http_cache.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:expensy/core/widgets/bottom_nav.dart';
import 'package:expensy/core/widgets/two_pane.dart';
import 'package:expensy/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fold users live in split screen, where the app can be squeezed to a third of
/// the cover display. Nothing may overflow and the nav must stay usable.
const _sizes = <String, Size>{
  'one third': Size(320, 700),
  'half': Size(370, 800),
  'small phone': Size(360, 640),
};

NavTab _tabFor(String location) =>
    location.startsWith('/transactions') ? NavTab.transactions : NavTab.home;

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required String location,
  double textScale = 1.0,
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
            builder: (_, _) => const TransactionsScreen(),
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
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  _sizes.forEach((label, size) {
    testWidgets('$label: single column, bottom nav, no overflow', (
      tester,
    ) async {
      await _pumpShell(tester, size: size, location: '/');

      expect(find.byType(TwoPane), findsNothing);
      expect(find.byType(BottomNav), findsOneWidget);
      // pumpWidget rethrows layout overflows, so reaching here is the
      // assertion; this just pins the intent.
      expect(tester.takeException(), isNull);
    });

    testWidgets('$label: transactions list fits', (tester) async {
      await _pumpShell(tester, size: size, location: '/transactions');

      expect(find.byType(BottomNav), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('bottom nav fits its five slots at 320dp', (tester) async {
    await _pumpShell(tester, size: const Size(320, 700), location: '/');

    final bar = tester.getSize(find.byType(BottomNav));
    expect(bar.width, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('largest system text size does not overflow the shell', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      size: const Size(360, 700),
      location: '/',
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
