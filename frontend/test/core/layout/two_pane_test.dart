import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

import 'package:expensy/core/layout/pane_scope.dart';
import 'package:expensy/core/widgets/two_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [TwoPane] into a window of [size] with the given display features.
Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> features = const [],
  Offset origin = Offset.zero,
  Widget primary = const Text('LEFT'),
  Widget secondary = const Text('RIGHT'),
}) {
  // The surface must actually be `size` — TwoPane reads LayoutBuilder
  // constraints, so a MediaQuery that disagrees with the view would silently
  // test the wrong geometry.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, displayFeatures: features),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TwoPane(origin: origin, primary: primary, secondary: secondary),
      ),
    ),
  );
}

DisplayFeature _fold({
  required Rect bounds,
  DisplayFeatureState state = DisplayFeatureState.postureFlat,
  DisplayFeatureType type = DisplayFeatureType.fold,
}) => DisplayFeature(bounds: bounds, type: type, state: state);

void main() {
  group('no display feature', () {
    testWidgets('splits evenly, left before right', (tester) async {
      await _pump(tester, size: const Size(900, 1000));

      final left = tester.getCenter(find.text('LEFT'));
      final right = tester.getCenter(find.text('RIGHT'));
      expect(left.dx, lessThan(right.dx));
      // Same row, not stacked.
      expect(left.dy, closeTo(right.dy, 0.5));
    });
  });

  group('vertical crease (book orientation)', () {
    testWidgets('splits at the hinge, not down the middle', (tester) async {
      // Asymmetric hinge so a mid-point split would be visibly wrong.
      await _pump(
        tester,
        size: const Size(900, 1000),
        features: [_fold(bounds: const Rect.fromLTRB(300, 0, 340, 1000))],
      );

      expect(tester.getSize(find.byType(ClipRect).first).width, 300);
      expect(
        tester.getCenter(find.text('LEFT')).dx,
        lessThan(tester.getCenter(find.text('RIGHT')).dx),
      );
    });

    testWidgets('splits side-by-side even when half opened', (tester) async {
      await _pump(
        tester,
        size: const Size(900, 1000),
        features: [
          _fold(
            bounds: const Rect.fromLTRB(440, 0, 460, 1000),
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );

      final left = tester.getCenter(find.text('LEFT'));
      final right = tester.getCenter(find.text('RIGHT'));
      expect(left.dx, lessThan(right.dx));
      expect(left.dy, closeTo(right.dy, 0.5));
    });

    testWidgets('honours origin when a rail sits to the left', (tester) async {
      // Window crease at x=384; TwoPane starts 84dp in, so locally that is 300.
      await _pump(
        tester,
        size: const Size(900, 1000),
        origin: const Offset(84, 0),
        features: [_fold(bounds: const Rect.fromLTRB(384, 0, 424, 1000))],
      );

      expect(tester.getSize(find.byType(ClipRect).first).width, 300);
    });
  });

  group('horizontal crease', () {
    testWidgets('flat keeps columns — it is just a wide screen', (
      tester,
    ) async {
      await _pump(
        tester,
        size: const Size(900, 800),
        features: [_fold(bounds: const Rect.fromLTRB(0, 390, 900, 410))],
      );

      final left = tester.getCenter(find.text('LEFT'));
      final right = tester.getCenter(find.text('RIGHT'));
      expect(left.dx, lessThan(right.dx));
      expect(left.dy, closeTo(right.dy, 0.5));
    });

    testWidgets('half opened is tabletop: primary above the crease', (
      tester,
    ) async {
      await _pump(
        tester,
        size: const Size(900, 800),
        features: [
          _fold(
            bounds: const Rect.fromLTRB(0, 390, 900, 410),
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );

      final top = tester.getCenter(find.text('LEFT'));
      final bottom = tester.getCenter(find.text('RIGHT'));
      expect(top.dy, lessThan(bottom.dy));
      expect(top.dx, closeTo(bottom.dx, 0.5));
      expect(tester.getSize(find.byType(ClipRect).first).height, 390);
    });
  });

  group('list-detail selection', () {
    testWidgets('both panes learn which detail is open', (tester) async {
      late String? fromPrimary;
      late String? fromSecondary;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 1000)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TwoPane(
              detailLocation: '/profile/goals',
              primary: Builder(
                builder: (context) {
                  fromPrimary = PaneScope.maybeOf(context)?.detailLocation;
                  return const SizedBox();
                },
              ),
              secondary: Builder(
                builder: (context) {
                  fromSecondary = PaneScope.maybeOf(context)?.detailLocation;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // The list pane needs it to mark the open row; the detail pane gets it
      // too so nested content can reason about its own selection.
      expect(fromPrimary, '/profile/goals');
      expect(fromSecondary, '/profile/goals');
      expect(
        PaneScope.isDetailSelected(
          tester.element(find.byType(SizedBox).first),
          '/profile/goals',
        ),
        isTrue,
      );
    });
  });

  group('pane scoping', () {
    testWidgets('each pane reports its own width, not the window', (
      tester,
    ) async {
      late double primaryWidth;
      late double secondaryWidth;
      late PaneRole primaryRole;
      late PaneRole secondaryRole;

      await _pump(
        tester,
        size: const Size(900, 1000),
        primary: Builder(
          builder: (context) {
            primaryWidth = MediaQuery.sizeOf(context).width;
            primaryRole = PaneScope.roleOf(context)!;
            return const SizedBox();
          },
        ),
        secondary: Builder(
          builder: (context) {
            secondaryWidth = MediaQuery.sizeOf(context).width;
            secondaryRole = PaneScope.roleOf(context)!;
            return const SizedBox();
          },
        ),
      );

      expect(primaryWidth, 450);
      expect(secondaryWidth, 450);
      expect(primaryRole, PaneRole.primary);
      expect(secondaryRole, PaneRole.secondary);
    });

    testWidgets('tabletop panes report their own height', (tester) async {
      late double topHeight;
      late double bottomHeight;

      await _pump(
        tester,
        size: const Size(900, 800),
        features: [
          _fold(
            bounds: const Rect.fromLTRB(0, 390, 900, 410),
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
        primary: Builder(
          builder: (context) {
            topHeight = MediaQuery.sizeOf(context).height;
            return const SizedBox();
          },
        ),
        secondary: Builder(
          builder: (context) {
            bottomHeight = MediaQuery.sizeOf(context).height;
            return const SizedBox();
          },
        ),
      );

      expect(topHeight, 390);
      expect(bottomHeight, 390);
    });
  });
}
