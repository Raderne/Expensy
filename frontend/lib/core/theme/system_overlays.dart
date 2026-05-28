import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Android status bar styles for screens with a blue hero header.
abstract final class AppSystemOverlays {
  static const hero = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
  );

  static const lightBackground = SystemUiOverlayStyle(
    statusBarColor: AppColors.surface,
    statusBarIconBrightness: Brightness.dark,
  );
}
