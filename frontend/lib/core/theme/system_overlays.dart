import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android/iOS status bar styles.
abstract final class AppSystemOverlays {
  /// For screens with a blue hero header — light icons over the gradient in
  /// every theme.
  static const hero = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
  );

  /// For plain backgrounds — status-bar icons follow the active theme so they
  /// stay legible in Light and Dark.
  static SystemUiOverlayStyle background(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemStatusBarContrastEnforced: false,
    );
  }
}
