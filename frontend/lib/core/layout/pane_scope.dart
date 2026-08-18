import 'package:flutter/widgets.dart';

/// Which half of a [TwoPane] a subtree is rendered in.
enum PaneRole {
  /// Left (or, in tabletop posture, top) pane — the navigated destination.
  primary,

  /// Right (or bottom) pane — the companion.
  secondary,
}

/// Marks a subtree as living inside a `TwoPane` pane.
///
/// Screens use this instead of re-deriving the size class, because inside a pane
/// the ambient [MediaQuery] reports the *pane's* size (deliberately — see
/// `TwoPane`), so `useTwoPane(context)` is false there even though the shell is
/// split. Anything that needs to know "am I one of two visible panes?" — hiding
/// content the companion already shows, for instance — must ask [PaneScope].
class PaneScope extends InheritedWidget {
  final PaneRole role;

  /// Route currently shown in the secondary pane, when the pairing is a
  /// list-detail one. Lets the primary pane mark the matching row as selected,
  /// so a detail view never appears to come from nowhere.
  final String? detailLocation;

  const PaneScope({
    super.key,
    required this.role,
    this.detailLocation,
    required super.child,
  });

  static PaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneScope>();

  /// True when this subtree is one of two side-by-side (or stacked) panes.
  static bool isInPane(BuildContext context) => maybeOf(context) != null;

  static PaneRole? roleOf(BuildContext context) => maybeOf(context)?.role;

  /// True when [route] is the detail currently shown beside this pane.
  static bool isDetailSelected(BuildContext context, String route) =>
      maybeOf(context)?.detailLocation == route;

  @override
  bool updateShouldNotify(PaneScope oldWidget) =>
      oldWidget.role != role || oldWidget.detailLocation != detailLocation;
}
