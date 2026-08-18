import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import '../theme/app_colors.dart';

/// Shared [showModalBottomSheet] defaults for Expensy sheets: transparent
/// chrome, the app scrim, scroll-controlled, and capped in width so a sheet does
/// not stretch edge-to-edge across a Fold inner display or tablet.
///
/// The cap goes through the modal route's own `constraints` rather than a
/// wrapper inside the builder. That matters on wide windows: the route then
/// knows the sheet is only 480 wide, so tapping the empty space beside a centred
/// sheet dismisses it. A wrapper would leave a full-width invisible sheet
/// swallowing those taps.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    // A no-op on phones, which are narrower than this anyway.
    constraints: const BoxConstraints(maxWidth: Breakpoints.sheetMaxWidth),
    builder: builder,
  );
}
