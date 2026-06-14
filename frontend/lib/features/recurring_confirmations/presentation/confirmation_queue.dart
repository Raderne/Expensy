import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/application/dashboard_controller.dart';
import '../../income/application/income_controller.dart';
import '../../recurring_expenses/application/recurring_expenses_controller.dart';
import '../../recurring_expenses/application/upcoming_bills_controller.dart';
import '../../transactions/application/transactions_controller.dart';
import '../application/pending_occurrences_controller.dart';
import '../application/postponed_occurrences_controller.dart';
import '../data/recurring_confirmations_repository.dart';
import '../domain/pending_occurrence.dart';
import 'confirmation_modal.dart';

// Re-entrancy guard: the dashboard listener and the add-recurring flow can both
// trigger the queue. A plain bool is enough — the queue is an app-global,
// single-threaded singleton.
bool _queueRunning = false;

/// Presents the confirm/postpone modal for every due occurrence, one at a time.
/// Dismissing a modal (tap outside) stops the queue — those items resurface on
/// the next app open. Uses the app-scoped [ProviderContainer] (not the widget
/// [WidgetRef]) so it survives the dashboard rebuilding mid-queue.
Future<void> runConfirmationQueue(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);

  if (_queueRunning) return;
  _queueRunning = true;

  try {
    final List<PendingOccurrence> due = await container.read(
      pendingOccurrencesControllerProvider.future,
    );
    if (due.isEmpty) return;

    final repo = container.read(recurringConfirmationsRepositoryProvider);

    for (final occurrence in due) {
      if (!context.mounted) break;
      final result = await showConfirmationModal(
        context,
        occurrence: occurrence,
      );
      if (result == null) break; // dismissed → decide later

      try {
        switch (result) {
          case ConfirmResult():
            await repo.confirm(occurrence.id);
          case PostponeResult(:final date):
            await repo.postpone(occurrence.id, date);
        }
      } on RecurringConfirmationsApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  } catch (_) {
    // Network failure fetching the list — silently skip; the next refresh
    // will retry.
  } finally {
    _queueRunning = false;
    // Reflect new transactions / cleared prompts everywhere. The recurring
    // lists carry each rule's postponed cycle, so refreshing them is what makes
    // a just-postponed date show up in the edit sheet.
    container.invalidate(pendingOccurrencesControllerProvider);
    container.invalidate(postponedOccurrencesControllerProvider);
    container.invalidate(dashboardControllerProvider);
    container.invalidate(upcomingBillsControllerProvider);
    container.invalidate(transactionsControllerProvider);
    container.invalidate(incomeControllerProvider);
    container.invalidate(recurringExpensesControllerProvider);
  }
}
