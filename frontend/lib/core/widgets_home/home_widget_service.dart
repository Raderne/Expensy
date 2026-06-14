import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../features/dashboard/application/dashboard_controller.dart';
import '../../features/dashboard/domain/dashboard_summary.dart';
import '../../features/dashboard/domain/recent_transaction.dart';

/// Pushes the latest dashboard snapshot to the Android home-screen widgets.
///
/// Data is written to the `home_widget` shared-preferences bucket as plain
/// strings/bools (numbers go out as strings so the Kotlin side never has to
/// guess int-vs-long over the platform channel), then each AppWidget provider
/// is asked to redraw. Whatever was last written survives in SharedPreferences,
/// so the widgets keep rendering current values even when the app isn't running.
class HomeWidgetService {
  HomeWidgetService._();

  // Must match the Kotlin AppWidgetProvider class simple names.
  static const _quickAddProvider = 'QuickAddWidgetProvider';
  static const _recentProvider = 'RecentTxWidgetProvider';
  static const _budgetProvider = 'BudgetWidgetProvider';

  /// Number of transaction rows the recent widget renders (fixed layout).
  static const _maxRows = 3;

  /// Serialize [state] into widget data and redraw all widgets.
  static Future<void> sync(DashboardState state) async {
    await _writeBudget(state.summary.budget);
    await _writeRecent(state.recentTransactions);
    await _updateAll();
  }

  /// Wipe widget data to its empty state (call on logout).
  static Future<void> clear() async {
    await HomeWidget.saveWidgetData<bool>('budget_is_set', false);
    await HomeWidget.saveWidgetData<String>('budget_pct', '0');
    await HomeWidget.saveWidgetData<String>('budget_spent', '');
    await HomeWidget.saveWidgetData<String>('budget_amount', '');
    await HomeWidget.saveWidgetData<String>('tx_count', '0');
    await _updateAll();
  }

  static Future<void> _writeBudget(BudgetInfo b) async {
    final money = NumberFormat.simpleCurrency(
      locale: 'en_US',
      decimalDigits: 0,
    );
    await HomeWidget.saveWidgetData<bool>('budget_is_set', b.isSet);
    await HomeWidget.saveWidgetData<String>(
      'budget_pct',
      b.pct.clamp(0, 100).toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'budget_spent',
      money.format(b.spent),
    );
    await HomeWidget.saveWidgetData<String>(
      'budget_amount',
      money.format(b.amount),
    );
  }

  static Future<void> _writeRecent(List<RecentTransaction> txs) async {
    final money = NumberFormat.simpleCurrency(locale: 'en_US');
    final count = txs.length < _maxRows ? txs.length : _maxRows;
    await HomeWidget.saveWidgetData<String>('tx_count', count.toString());

    for (var i = 0; i < _maxRows; i++) {
      if (i < count) {
        final t = txs[i];
        final isIncome = t.amount >= 0;
        final amount = '${isIncome ? '+' : '-'}${money.format(t.amount.abs())}';
        await HomeWidget.saveWidgetData<String>(
          'tx${i}_label',
          t.category.label,
        );
        await HomeWidget.saveWidgetData<String>('tx${i}_note', t.note ?? '');
        await HomeWidget.saveWidgetData<String>('tx${i}_amount', amount);
        await HomeWidget.saveWidgetData<bool>('tx${i}_income', isIncome);
        await HomeWidget.saveWidgetData<String>('tx${i}_abbr', t.category.abbr);
        await HomeWidget.saveWidgetData<String>(
          'tx${i}_color',
          t.category.color,
        );
        await HomeWidget.saveWidgetData<String>(
          'tx${i}_date',
          _relativeDate(t.occurredAt),
        );
      } else {
        // Clear stale rows so a deleted/older transaction doesn't linger.
        await HomeWidget.saveWidgetData<String>('tx${i}_label', '');
        await HomeWidget.saveWidgetData<String>('tx${i}_note', '');
        await HomeWidget.saveWidgetData<String>('tx${i}_amount', '');
        await HomeWidget.saveWidgetData<String>('tx${i}_abbr', '');
        await HomeWidget.saveWidgetData<String>('tx${i}_date', '');
      }
    }
  }

  static Future<void> _updateAll() async {
    await Future.wait([
      HomeWidget.updateWidget(androidName: _quickAddProvider),
      HomeWidget.updateWidget(androidName: _recentProvider),
      HomeWidget.updateWidget(androidName: _budgetProvider),
    ]);
  }

  /// Mirrors the relative-date format used by the in-app Recent activity card.
  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '$diff days ago';
    return DateFormat('MMM d').format(d);
  }
}
