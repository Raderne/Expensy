import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true on an expanded window, the shell's right pane shows Add Expense
/// (overriding the tab's default companion). Compact still uses `/add` modal.
final expandedAddPaneProvider = NotifierProvider<ExpandedAddPane, bool>(
  ExpandedAddPane.new,
);

class ExpandedAddPane extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;

  void toggle() => state = !state;
}
