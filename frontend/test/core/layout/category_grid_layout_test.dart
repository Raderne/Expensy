import 'package:expensy/core/models/category.dart';
import 'package:expensy/features/add_expense/presentation/widgets/category_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cats = List.generate(
    6,
    (i) => Category(
      id: 'c$i',
      key: 'key$i',
      label: 'Cat $i',
      abbr: 'C$i',
      color: '#1B45D0',
      bgTint: '#EEF3FF',
      isSystem: false,
    ),
  );

  testWidgets('CategoryGrid sizes tiles from parent width not window', (
    tester,
  ) async {
    // Wide window, narrow pane — tiles must fit the 300dp pane (3 columns).
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: CategoryGrid(
                categories: cats,
                selectedId: null,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(); // post-frame metric update

    // 3 tiles: (300 - 16) / 3 ≈ 94.67. Height = 2*tile + 8.
    final grid = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byType(CategoryGrid),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(grid.height, closeTo(94.67 * 2 + 8, 1.0));
  });

  testWidgets('CategoryGrid uses 4 tiles per row on roomy panes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: CategoryGrid(
                categories: cats,
                selectedId: null,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 4 tiles: (400 - 24) / 4 = 94. Height = 2*94 + 8 = 196.
    final grid = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byType(CategoryGrid),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(grid.height, closeTo(196, 1.0));
  });
}
