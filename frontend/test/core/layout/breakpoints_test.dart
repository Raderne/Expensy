import 'package:expensy/core/layout/breakpoints.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('windowSizeClassForWidth', () {
    test('compact below 600', () {
      expect(windowSizeClassForWidth(320), WindowSizeClass.compact);
      expect(windowSizeClassForWidth(399), WindowSizeClass.compact);
      expect(windowSizeClassForWidth(599), WindowSizeClass.compact);
    });

    test('medium from 600 inclusive to 699', () {
      expect(windowSizeClassForWidth(600), WindowSizeClass.medium);
      expect(windowSizeClassForWidth(699), WindowSizeClass.medium);
    });

    test('expanded at 700 and above', () {
      expect(windowSizeClassForWidth(700), WindowSizeClass.expanded);
      expect(windowSizeClassForWidth(900), WindowSizeClass.expanded);
    });
  });

  group('useTwoPaneForSize', () {
    // The whole point of the 700 threshold: a stock Galaxy Z Fold 7 inner
    // display is ~750 x 832 dp at 420 dpi, so Material's 840 is never reached
    // in either orientation. These are the sizes that must work.
    test('Fold 7 inner display splits in both orientations', () {
      expect(
        useTwoPaneForSize(const Size(750, 832)),
        isTrue,
        reason: 'portrait',
      );
      expect(
        useTwoPaneForSize(const Size(832, 750)),
        isTrue,
        reason: 'landscape',
      );
    });

    test('Fold cover screen and split-screen panes stay single column', () {
      expect(useTwoPaneForSize(const Size(420, 940)), isFalse, reason: 'cover');
      expect(
        useTwoPaneForSize(const Size(320, 800)),
        isFalse,
        reason: '1/3 split',
      );
      expect(
        useTwoPaneForSize(const Size(370, 800)),
        isFalse,
        reason: '1/2 split',
      );
    });

    test('wide but short windows stay single column', () {
      // A phone in landscape is wider than 700 but far too short for two panes.
      expect(useTwoPaneForSize(const Size(915, 412)), isFalse);
      expect(useTwoPaneForSize(const Size(900, 479)), isFalse);
      expect(useTwoPaneForSize(const Size(900, 480)), isTrue);
    });

    test('exact width threshold', () {
      expect(useTwoPaneForSize(const Size(699, 900)), isFalse);
      expect(useTwoPaneForSize(const Size(700, 900)), isTrue);
    });
  });

  group('pageInsetsOf', () {
    test('compact width gets the phone gutter', () {
      expect(pageInsetsOf(390).left, 18);
    });

    test('medium width gets a roomier gutter', () {
      expect(pageInsetsOf(640).left, 28);
    });

    test('beyond the reading measure the column is centred, not stretched', () {
      // 900 - 640 = 260 of slack, split evenly.
      expect(pageInsetsOf(900).left, 130);
      expect(pageInsetsOf(900).right, 130);
    });

    test('never narrower than the gutter', () {
      expect(pageInsetsOf(650).left, greaterThanOrEqualTo(28));
      expect(pageInsetsOf(300).left, 18);
    });
  });
}
