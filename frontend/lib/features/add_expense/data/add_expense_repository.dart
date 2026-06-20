import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../dashboard/domain/recent_transaction.dart';
import '../../shared/domain/expense_split_draft.dart';

class AddExpenseRepository {
  final OutboxWriter _outbox;
  const AddExpenseRepository(this._outbox);

  /// Queues an expense create and returns the optimistic row to render right
  /// away. The actual `POST /transactions` is performed later by the SyncEngine;
  /// [idempotencyKey] keeps a replayed write from double-posting.
  ///
  /// The server stores expenses as a negative amount (client sends positive and
  /// the API negates), so the optimistic row mirrors that sign to match what a
  /// later refetch will return.
  Future<RecentTransaction> createExpense({
    required Category category,
    required double amount,
    String? note,
    DateTime? occurredAt,
    List<ExpenseSplitDraft> splits = const [],
    required String idempotencyKey,
  }) async {
    final tempId = _outbox.newTempId();
    // Store at local day granularity (the app only ever displays the day, never
    // a time). This keeps all transactions ordered by creation within a day,
    // instead of letting a fresh expense's time-of-day float it above earlier
    // same-day rows that are stored at start-of-day (recurring, income).
    final raw = occurredAt ?? DateTime.now();
    final when = DateTime(raw.year, raw.month, raw.day);
    final trimmedNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : null;
    // Only contacts with a positive owed share are sent; the user's own share is
    // implicit on the server.
    final activeSplits = splits.where((s) => s.owedAmount > 0).toList();

    await _outbox.enqueue(
      kind: 'txCreate',
      method: 'POST',
      path: '/transactions',
      idempotencyKey: idempotencyKey,
      tempId: tempId,
      body: {
        // May be a temp category id if the category was also created offline;
        // the SyncEngine rewrites it to the real id before this write replays.
        'categoryId': category.id,
        'amount': amount,
        'note': ?trimmedNote,
        'occurredAt': when.toUtc().toIso8601String(),
        if (activeSplits.isNotEmpty)
          'splits': activeSplits.map((s) => s.toJson()).toList(),
      },
    );

    return RecentTransaction(
      id: tempId,
      amount: -amount,
      note: trimmedNote,
      occurredAt: when,
      category: category,
      pending: true,
    );
  }
}

final addExpenseRepositoryProvider = Provider<AddExpenseRepository>(
  (ref) => AddExpenseRepository(ref.watch(outboxWriterProvider)),
);
