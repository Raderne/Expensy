import 'package:expensy/core/cache/http_cache.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:expensy/features/add_expense/presentation/add_expense_screen.dart';
import 'package:expensy/features/add_expense/presentation/widgets/numpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A companion pane on a Fold 7 inner display: half of (750 - 84 dp rail).
const _paneSize = Size(333, 832);

Future<void> _pumpPane(WidgetTester tester, {Size size = _paneSize}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        httpCacheProvider.overrideWithValue(InMemoryHttpCache()),
        outboxProvider.overrideWithValue(InMemoryOutbox()),
      ],
      child: MaterialApp(
        home: Scaffold(body: AddExpenseScreen(embedded: true, onClose: () {})),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('Save and the numpad are pinned inside the pane', (tester) async {
    await _pumpPane(tester);

    final save = find.text('Save Expense');
    expect(save, findsOneWidget);
    expect(find.byType(Numpad), findsOneWidget);

    // The whole point of the pane layout: no scrolling to reach the button,
    // and nothing hanging off the bottom of the pane.
    final saveRect = tester.getRect(save);
    expect(saveRect.bottom, lessThanOrEqualTo(_paneSize.height));
    expect(saveRect.top, greaterThan(0));

    // Save sits below the numpad, which sits below the amount.
    expect(
      tester.getRect(find.byType(Numpad)).bottom,
      lessThanOrEqualTo(saveRect.top),
    );
  });

  testWidgets('the middle section is the part that scrolls', (tester) async {
    await _pumpPane(tester);

    // Exactly one scroll view: the category/note region. A pinned action zone
    // means the page as a whole does not scroll.
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('Save stays reachable in a short pane too', (tester) async {
    // Tabletop posture halves the height.
    await _pumpPane(tester, size: const Size(333, 400));

    final saveRect = tester.getRect(find.text('Save Expense'));
    expect(saveRect.bottom, lessThanOrEqualTo(400));
  });
}
