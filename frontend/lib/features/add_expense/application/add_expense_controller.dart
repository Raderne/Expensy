import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../analytics/application/analytics_controller.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../dashboard/domain/recent_transaction.dart';
import '../../transactions/application/transactions_controller.dart';
import '../data/add_expense_repository.dart';
import '../domain/amount_input.dart';

@immutable
class AddExpenseState {
  final String amount;
  final String? categoryId;
  final String note;
  final bool saving;
  final RecentTransaction? saved;
  final String? error;

  const AddExpenseState({
    this.amount = '0',
    this.categoryId,
    this.note = '',
    this.saving = false,
    this.saved,
    this.error,
  });

  bool get canSave =>
      !saving && categoryId != null && AmountInput.isValid(amount);

  AddExpenseState copyWith({
    String? amount,
    String? categoryId,
    String? note,
    bool? saving,
    RecentTransaction? saved,
    String? error,
    bool clearSaved = false,
    bool clearError = false,
  }) =>
      AddExpenseState(
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        saving: saving ?? this.saving,
        saved: clearSaved ? null : (saved ?? this.saved),
        error: clearError ? null : (error ?? this.error),
      );
}

class AddExpenseController extends Notifier<AddExpenseState> {
  @override
  AddExpenseState build() => const AddExpenseState();

  void pressDigit(int d) =>
      state = state.copyWith(amount: AmountInput.digit(state.amount, d), clearError: true);

  void pressDot() =>
      state = state.copyWith(amount: AmountInput.dot(state.amount), clearError: true);

  void pressBackspace() =>
      state = state.copyWith(amount: AmountInput.backspace(state.amount), clearError: true);

  void selectCategory(Category c) =>
      state = state.copyWith(categoryId: c.id, clearError: true);

  void setNote(String value) => state = state.copyWith(note: value);

  /// Resets to a clean slate. Used after "Add Another".
  void reset() {
    state = const AddExpenseState();
  }

  Future<void> save() async {
    if (!state.canSave) return;

    state = state.copyWith(saving: true, clearError: true);
    try {
      final tx = await ref.read(addExpenseRepositoryProvider).createExpense(
            categoryId: state.categoryId!,
            amount: AmountInput.parse(state.amount),
            note: state.note.trim().isEmpty ? null : state.note.trim(),
          );
      // Invalidate downstream caches so a return to Dashboard / Transactions /
      // Analytics shows the new row without a manual refresh.
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(transactionsControllerProvider);
      ref.invalidate(analyticsControllerProvider);
      state = state.copyWith(saving: false, saved: tx);
    } on AddExpenseApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
    } catch (_) {
      state = state.copyWith(saving: false, error: 'Could not save. Try again.');
    }
  }
}

final addExpenseControllerProvider =
    NotifierProvider<AddExpenseController, AddExpenseState>(
  AddExpenseController.new,
);
