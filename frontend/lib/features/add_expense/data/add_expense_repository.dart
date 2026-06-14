import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../dashboard/domain/recent_transaction.dart';

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
    required String idempotencyKey,
  }) async {
    final tempId = _outbox.newTempId();
    final when = occurredAt ?? DateTime.now();
    final trimmedNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : null;

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
