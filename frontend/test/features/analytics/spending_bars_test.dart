import 'package:expensy/features/analytics/domain/analytics_breakdown.dart';
import 'package:expensy/features/analytics/presentation/widgets/spending_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  BreakdownItem(
    categoryId: 'c-home',
    key: 'home',
    label: 'Home',
    color: '#4F6CF7',
    amount: 1100,
    pct: 0.5,
  ),
  BreakdownItem(
    categoryId: 'c-food',
    key: 'food',
    label: 'Food',
    color: '#F79E4F',
    amount: 550,
    pct: 0.25,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  String? selectedCategoryId,
  ValueChanged<String>? onSelect,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SpendingBars(
          items: _items,
          selectedCategoryId: selectedCategoryId,
          onSelect: onSelect,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('read-only by default: no tap surface', (tester) async {
    await _pump(tester);

    expect(find.text('Home'), findsOneWidget);
    // Without onSelect the rows are plain, so the compact screen keeps its
    // existing non-interactive breakdown.
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('tapping a row reports its category', (tester) async {
    final tapped = <String>[];
    await _pump(tester, onSelect: tapped.add);

    await tester.tap(find.text('Food'));
    await tester.pump();

    expect(tapped, ['c-food']);
  });

  testWidgets('selection is announced, not carried by colour alone', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, selectedCategoryId: 'c-home', onSelect: (_) {});

    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Home,'))),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Home, \$1,100, 50 percent',
      ),
    );
    handle.dispose();
  });
}
