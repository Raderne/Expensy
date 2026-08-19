import 'package:flutter/material.dart';

import '../widgets/two_pane.dart';

/// One destination laid out for an expanded window: a single header band across
/// the full content width, with two content panes underneath it.
///
/// The point is that the panes carry *content only*. Before this existed the
/// shell put a whole phone screen in each pane, so an unfolded device showed two
/// status-bar heroes, two titles and — on Stats — the same month twice. Here the
/// destination states its context once, at the top, and the panes below are free
/// to be purpose-built for the space they have.
///
/// Pane sizing, fold/crease awareness and the pane-scoped `MediaQuery` all stay
/// in [TwoPane]; this widget only positions it and keeps the crease math honest.
class ExpandedDestination extends StatelessWidget {
  /// Full-width band above the panes. Sizes itself.
  final Widget header;

  final Widget primary;
  final Widget secondary;

  /// Semantic labels for the panes (TalkBack / VoiceOver).
  final String? primaryLabel;
  final String? secondaryLabel;

  /// Route shown in the secondary pane for list-detail pairings.
  final String? detailLocation;

  /// Position of this widget's top-left corner in window coordinates. Display
  /// features are reported in window space, so the crease can only be located
  /// once we know how far in the navigation rail (and any safe-area inset) has
  /// pushed us.
  final Offset origin;

  const ExpandedDestination({
    super.key,
    required this.header,
    required this.primary,
    required this.secondary,
    this.primaryLabel,
    this.secondaryLabel,
    this.detailLocation,
    this.origin = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) {
        final totalHeight = outer.maxHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gutters come from `pageInsetOf`, which reads the ambient
            // MediaQuery. Left to itself the header would size them against the
            // full 666 dp band and centre its content 55 dp in, while the cards
            // in the pane directly below sit 18 dp in. Report a pane-sized
            // width so the two line up. This changes only the gutter maths —
            // the header still lays out across the full width.
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(size: Size(outer.maxWidth / 2, outer.maxHeight)),
              child: header,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, inner) {
                  // The header's exact height, resolved in the same layout pass:
                  // whatever the Column did not hand to the panes went to it.
                  // A post-frame measure would paint one frame with the crease
                  // in the wrong place, which is visible as a jump on unfold.
                  final headerHeight = totalHeight - inner.maxHeight;
                  return TwoPane(
                    origin: origin + Offset(0, headerHeight),
                    primary: primary,
                    secondary: secondary,
                    primaryLabel: primaryLabel,
                    secondaryLabel: secondaryLabel,
                    detailLocation: detailLocation,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
