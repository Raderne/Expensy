import 'dart:ui' show DisplayFeatureType, DisplayFeatureState;

import 'package:flutter/material.dart';

import '../layout/pane_scope.dart';
import '../theme/app_colors.dart';

/// Side-by-side (or, in tabletop posture, stacked) panes for expanded windows.
///
/// Fold awareness comes from [MediaQuery.displayFeatures]:
///
/// * A **vertical** fold/hinge (Fold held in book orientation) splits the panes
///   left/right at the crease so content is never drawn through it.
/// * A **horizontal** fold that is *half opened* is tabletop posture: the panes
///   stack, [primary] above the crease and [secondary] below, so the top half
///   stays glanceable while the bottom half is the reachable, touchable half.
/// * A horizontal fold that is **flat** is just a landscape screen — it keeps
///   the side-by-side split, which suits a wide/short window far better than
///   two short rows.
/// * No usable feature (tablets, the seamless Fold 7 crease) falls back to an
///   even 1:1 split with a hairline divider.
///
/// Each pane installs its own [MediaQuery] reporting the *pane's* size, so every
/// screen inside lays out against the space it actually has rather than the full
/// window. Screens that need to know they are one of two panes must ask
/// [PaneScope] — `useTwoPane(context)` is intentionally false inside a pane.
class TwoPane extends StatelessWidget {
  final Widget primary;
  final Widget secondary;

  /// Optional semantic labels for the panes (TalkBack / VoiceOver).
  final String? primaryLabel;
  final String? secondaryLabel;

  /// Position of this widget's top-left corner in window coordinates.
  ///
  /// [MediaQuery.displayFeatures] bounds are reported in window space, so the
  /// crease can only be located correctly if we know how far this widget is
  /// inset — by a navigation rail on the left, for instance.
  final Offset origin;

  /// Route shown in the secondary pane for list-detail pairings. Published to
  /// both panes via [PaneScope] so the list can mark the open row.
  final String? detailLocation;

  const TwoPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryLabel,
    this.secondaryLabel,
    this.origin = Offset.zero,
    this.detailLocation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final split = _foldSplit(context, size);

        if (split != null && !split.foldIsVertical) {
          return _stacked(size, split);
        }
        if (split != null) {
          return _sideBySide(size, split);
        }
        return _sideBySide(size, null);
      },
    );
  }

  Widget _sideBySide(Size size, _FoldSplit? split) {
    final width = size.width;
    if (split == null) {
      final half = width / 2;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _pane(Size(half, size.height), PaneRole.primary)),
          const _Divider(axis: Axis.vertical),
          Expanded(child: _pane(Size(half, size.height), PaneRole.secondary)),
        ],
      );
    }

    final leftW = split.bounds.left.clamp(0.0, width);
    final rightStart = split.bounds.right.clamp(0.0, width);
    final rightW = (width - rightStart).clamp(0.0, width);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: leftW,
          child: _pane(Size(leftW, size.height), PaneRole.primary),
        ),
        if (split.bounds.width > 0)
          SizedBox(width: split.bounds.width)
        else
          const _Divider(axis: Axis.vertical),
        SizedBox(
          width: rightW,
          child: _pane(Size(rightW, size.height), PaneRole.secondary),
        ),
      ],
    );
  }

  /// Tabletop: [primary] above the crease, [secondary] below.
  Widget _stacked(Size size, _FoldSplit split) {
    final height = size.height;
    final topH = split.bounds.top.clamp(0.0, height);
    final bottomStart = split.bounds.bottom.clamp(0.0, height);
    final bottomH = (height - bottomStart).clamp(0.0, height);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: topH,
          child: _pane(Size(size.width, topH), PaneRole.primary),
        ),
        if (split.bounds.height > 0)
          SizedBox(height: split.bounds.height)
        else
          const _Divider(axis: Axis.horizontal),
        SizedBox(
          height: bottomH,
          child: _pane(Size(size.width, bottomH), PaneRole.secondary),
        ),
      ],
    );
  }

  Widget _pane(Size size, PaneRole role) {
    final isPrimary = role == PaneRole.primary;
    return _Pane(
      size: size,
      role: role,
      detailLocation: detailLocation,
      label: isPrimary ? primaryLabel : secondaryLabel,
      child: isPrimary ? primary : secondary,
    );
  }

  /// Locates a usable fold/hinge in local coordinates, or null when the layout
  /// should fall back to an even split.
  _FoldSplit? _foldSplit(BuildContext context, Size size) {
    for (final f in MediaQuery.displayFeaturesOf(context)) {
      if (f.type != DisplayFeatureType.hinge &&
          f.type != DisplayFeatureType.fold) {
        continue;
      }
      final b = f.bounds.shift(-origin);
      final halfOpened = f.state == DisplayFeatureState.postureHalfOpened;

      // Crease running top-to-bottom: tall, narrow, spanning most of the height.
      if (b.height >= size.height * 0.8 && b.width < size.width * 0.25) {
        return _FoldSplit(bounds: b, foldIsVertical: true);
      }
      // Crease running left-to-right: only worth stacking for when half opened.
      // Flat, it is just a wide landscape screen and columns beat rows.
      if (halfOpened &&
          b.width >= size.width * 0.8 &&
          b.height < size.height * 0.25) {
        return _FoldSplit(bounds: b, foldIsVertical: false);
      }
    }
    return null;
  }
}

class _FoldSplit {
  final Rect bounds;

  /// True when the crease runs top-to-bottom, i.e. panes sit side by side.
  final bool foldIsVertical;

  const _FoldSplit({required this.bounds, required this.foldIsVertical});
}

class _Pane extends StatelessWidget {
  final String? label;
  final Size size;
  final PaneRole role;
  final String? detailLocation;
  final Widget child;

  const _Pane({
    required this.child,
    required this.size,
    required this.role,
    this.detailLocation,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Report the pane's own size so screens inside lay out against the space
    // they actually have. Padding and viewInsets pass through: the enclosing
    // SafeArea already consumed the horizontal insets, and the keyboard still
    // covers the bottom of whichever pane owns the focused field.
    Widget content = MediaQuery(
      data: MediaQuery.of(context).copyWith(size: size),
      child: PaneScope(
        role: role,
        detailLocation: detailLocation,
        child: ClipRect(child: child),
      ),
    );
    if (label != null) {
      content = Semantics(container: true, label: label, child: content);
    }
    return content;
  }
}

class _Divider extends StatelessWidget {
  final Axis axis;

  const _Divider({required this.axis});

  @override
  Widget build(BuildContext context) {
    // A true hairline: one physical pixel, not one logical pixel.
    final t = 1 / MediaQuery.devicePixelRatioOf(context);
    return ColoredBox(
      color: AppColors.border,
      child: axis == Axis.vertical ? SizedBox(width: t) : SizedBox(height: t),
    );
  }
}
