import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets_home/widget_appearance_service.dart';
import '../data/settings_store.dart';
import '../domain/widget_appearance.dart';

/// Holds per-widget appearance config, seeded synchronously from storage.
/// Every change is persisted and pushed to the matching Android widget.
final widgetAppearanceProvider =
    NotifierProvider<
      WidgetAppearanceController,
      Map<WidgetType, WidgetAppearance>
    >(WidgetAppearanceController.new);

class WidgetAppearanceController
    extends Notifier<Map<WidgetType, WidgetAppearance>> {
  String _key(WidgetType t) => 'widget_appearance_${t.name}';

  @override
  Map<WidgetType, WidgetAppearance> build() {
    final store = ref.watch(settingsStoreProvider);
    return {
      for (final t in WidgetType.values)
        t: WidgetAppearance.decode(store.getString(_key(t))),
    };
  }

  Future<void> set(WidgetType type, WidgetAppearance appearance) async {
    state = {...state, type: appearance};
    await ref
        .read(settingsStoreProvider)
        .setString(_key(type), appearance.encode());
    await WidgetAppearanceService.apply(type, appearance);
  }
}
