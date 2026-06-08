import 'package:home_widget/home_widget.dart';

import '../../features/settings/domain/widget_appearance.dart';

/// Pushes per-widget appearance settings to the Android home-screen widgets.
///
/// Writes the same `wcfg_<prefix>_*` keys the Kotlin providers read, then asks
/// the affected provider to redraw. Values go out as strings to match the rest
/// of the home_widget bridge (the Kotlin side never has to guess int-vs-long).
class WidgetAppearanceService {
  WidgetAppearanceService._();

  /// Write one widget type's config and redraw it.
  static Future<void> apply(WidgetType type, WidgetAppearance a) async {
    await _write(type, a);
    await HomeWidget.updateWidget(androidName: type.providerName);
  }

  /// Write every widget type's config and redraw all of them. Use on launch so
  /// the widgets reflect saved settings even after a reinstall/clear.
  static Future<void> applyAll(Map<WidgetType, WidgetAppearance> all) async {
    for (final entry in all.entries) {
      await _write(entry.key, entry.value);
    }
    await Future.wait([
      for (final type in all.keys)
        HomeWidget.updateWidget(androidName: type.providerName),
    ]);
  }

  static Future<void> _write(WidgetType type, WidgetAppearance a) async {
    final p = type.prefix;
    await HomeWidget.saveWidgetData<String>('wcfg_${p}_bg', a.bg.wire);
    await HomeWidget.saveWidgetData<String>(
      'wcfg_${p}_opacity',
      a.opacity.clamp(0, 100).toString(),
    );
    await HomeWidget.saveWidgetData<String>('wcfg_${p}_color', a.color.wire);
  }
}
