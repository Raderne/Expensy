import 'package:intl/intl.dart';

import 'transaction.dart';

/// Grouped section ready for rendering.
class TransactionGroup {
  final String label; // e.g. "TODAY", "YESTERDAY", "MAY 21"
  final List<Transaction> transactions;
  const TransactionGroup({required this.label, required this.transactions});
}

/// Buckets transactions by local-day. Within a day, ordering is preserved
/// (the controller hands us newest-first, so the row order is correct already).
/// Labels: "TODAY" / "YESTERDAY" / "MMM d" — uppercased (styling is in the
/// widget, but we uppercase here so equality checks line up cleanly).
List<TransactionGroup> groupByDay(List<Transaction> txs, {DateTime? now}) {
  if (txs.isEmpty) return const [];

  final today = _dayStart(now ?? DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  final fmt = DateFormat('MMM d');

  final groups = <DateTime, List<Transaction>>{};
  for (final tx in txs) {
    final day = _dayStart(tx.occurredAt);
    groups.putIfAbsent(day, () => <Transaction>[]).add(tx);
  }

  // Days come out in insertion order; since txs are newest-first, that order
  // is already correct. We just need stable labels.
  return groups.entries.map((e) {
    final String label;
    if (e.key == today) {
      label = 'TODAY';
    } else if (e.key == yesterday) {
      label = 'YESTERDAY';
    } else {
      label = fmt.format(e.key).toUpperCase();
    }
    return TransactionGroup(label: label, transactions: e.value);
  }).toList();
}

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
