import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Direction of the last month change: +1 newer, -1 older.
///
/// Drives the slide direction of the transactions body transition so it tracks
/// the gesture that caused it. It lives in a provider rather than in widget
/// state because on an expanded window the chevrons are in the destination
/// header while the sliding body is in a pane — two separate subtrees.
final monthNavDirectionProvider = NotifierProvider<MonthNavDirection, int>(
  MonthNavDirection.new,
);

class MonthNavDirection extends Notifier<int> {
  @override
  int build() => 1;

  void older() => state = -1;

  void newer() => state = 1;
}
