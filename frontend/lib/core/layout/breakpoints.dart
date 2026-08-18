import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Material 3-inspired window size classes driven by the current window width.
///
/// Used for adaptive layouts (Fold cover vs inner screen, tablets). Prefer this
/// over device-model checks so any similarly wide display gets the same UX.
enum WindowSizeClass {
  /// Phone / Fold cover / split-screen pane (`width < 600`).
  compact,

  /// Slightly wider single column (`600–699`). Extra gutters, no two-pane.
  medium,

  /// Fold inner / tablet (`width >= 700`). Two-pane layouts.
  expanded,
}

/// Compact / medium / expanded thresholds in logical pixels.
abstract final class Breakpoints {
  static const double medium = 600;

  /// Two-pane threshold.
  ///
  /// Deliberately below Material's 840: Samsung documents Z Fold devices as
  /// *medium* in both orientations, and a Fold 7 inner display measures roughly
  /// 750 x 832 dp at the stock 420 dpi. An 840 threshold is never reached on the
  /// device this adaptation exists for.
  static const double expanded = 700;

  /// Two-pane also needs vertical room — a phone in landscape is wide but short,
  /// and two ~400 dp-tall panes are worse than one full-height column.
  static const double minTwoPaneHeight = 480;

  /// Comfortable reading measure for a single content column. Beyond this the
  /// column is centered rather than stretched.
  static const double contentMax = 640;

  /// Max width for auth form cards and modal sheets on wide windows.
  static const double sheetMaxWidth = 480;
  static const double authFormMaxWidth = 440;
}

extension WindowSizeClassX on WindowSizeClass {
  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMedium => this == WindowSizeClass.medium;
  bool get isExpanded => this == WindowSizeClass.expanded;
}

/// Resolves [WindowSizeClass] from a logical width.
WindowSizeClass windowSizeClassForWidth(double width) {
  if (width >= Breakpoints.expanded) return WindowSizeClass.expanded;
  if (width >= Breakpoints.medium) return WindowSizeClass.medium;
  return WindowSizeClass.compact;
}

/// Convenience: read the size class from the nearest [MediaQuery].
WindowSizeClass windowSizeClassOf(BuildContext context) =>
    windowSizeClassForWidth(MediaQuery.sizeOf(context).width);

/// Whether the shell should split into side-by-side panes.
///
/// Width *and* height are considered so a landscape phone (wide, short) keeps
/// its single column. This is the single decision predicate — do not re-derive
/// it from the size class alone.
bool useTwoPaneForSize(Size size) =>
    size.width >= Breakpoints.expanded &&
    size.height >= Breakpoints.minTwoPaneHeight;

/// [useTwoPaneForSize] against the nearest [MediaQuery].
///
/// Note this reads whatever [MediaQuery] is in scope: inside a `TwoPane` pane
/// that is the *pane's* size, so it correctly reports `false` there.
bool useTwoPane(BuildContext context) =>
    useTwoPaneForSize(MediaQuery.sizeOf(context));

/// Horizontal page gutter that grows slightly on medium+ widths.
double pageGutterForWidth(double width) =>
    width >= Breakpoints.medium ? 28 : 18;

/// Horizontal insets for a page's scrollable content: a gutter that grows with
/// the available width, plus centring slack once the column would exceed
/// [maxContent].
///
/// [width] is the width of the box the content lives in — take it from a
/// [LayoutBuilder], `SliverConstraints.crossAxisExtent`, or the pane-scoped
/// [MediaQuery]. Never from the raw window width inside a pane.
EdgeInsets pageInsetsOf(
  double width, {
  double maxContent = Breakpoints.contentMax,
}) {
  final gutter = pageGutterForWidth(width);
  final slack = (width - maxContent) / 2;
  return EdgeInsets.symmetric(horizontal: math.max(gutter, slack));
}

/// Page gutter for the width currently in scope.
///
/// Inside a `TwoPane` pane this is the pane's width, not the window's, so a
/// 335 dp pane gets phone gutters while a wide single column gets its content
/// centred instead of stretched.
double pageInsetOf(BuildContext context) =>
    pageInsetsOf(MediaQuery.sizeOf(context).width).left;

/// [pageInsetOf], floored at the hero's own 22 dp inset so a full-bleed header
/// keeps its established look while still aligning with the body column.
double heroInsetOf(BuildContext context) => math.max(22, pageInsetOf(context));
