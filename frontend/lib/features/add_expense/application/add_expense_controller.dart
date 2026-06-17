import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/categories_repository.dart';
import '../../../core/models/category.dart';
import '../../dashboard/domain/recent_transaction.dart';
import '../../shared/domain/expense_split_draft.dart';
import '../data/add_expense_repository.dart';
import '../domain/amount_input.dart';

@immutable
class AddExpenseState {
  final String amount;
  final String? categoryId;
  final String note;
  final List<ExpenseSplitDraft> splits;
  final bool saving;
  final RecentTransaction? saved;
  final String? error;

  const AddExpenseState({
    this.amount = '0',
    this.categoryId,
    this.note = '',
    this.splits = const [],
    this.saving = false,
    this.saved,
    this.error,
  });

  /// Part of the bill owed by other people.
  double get owedTotal => totalOwed(splits);

  /// True when others' shares meet/exceed the bill — the user must keep some.
  bool get overSplit {
    final amt = AmountInput.parse(amount);
    return owedTotal > 0 && amt > 0 && owedTotal >= amt;
  }

  bool get canSave =>
      !saving && categoryId != null && AmountInput.isValid(amount) && !overSplit;

  AddExpenseState copyWith({
    String? amount,
    String? categoryId,
    String? note,
    List<ExpenseSplitDraft>? splits,
    bool? saving,
    RecentTransaction? saved,
    String? error,
    bool clearSaved = false,
    bool clearError = false,
  }) => AddExpenseState(
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    splits: splits ?? this.splits,
    saving: saving ?? this.saving,
    saved: clearSaved ? null : (saved ?? this.saved),
    error: clearError ? null : (error ?? this.error),
  );
}

class AddExpenseController extends Notifier<AddExpenseState> {
  // One idempotency key per logical expense entry. Reused across retries (so a
  // slow/duplicated submit dedupes server-side) and rotated once the expense is
  // saved or the form is reset for "Add another".
  String _idempotencyKey = const Uuid().v4();

  @override
  AddExpenseState build() => const AddExpenseState();

  void pressDigit(int d) => state = state.copyWith(
    amount: AmountInput.digit(state.amount, d),
    clearError: true,
  );

  void pressDot() => state = state.copyWith(
    amount: AmountInput.dot(state.amount),
    clearError: true,
  );

  void pressBackspace() => state = state.copyWith(
    amount: AmountInput.backspace(state.amount),
    clearError: true,
  );

  void selectCategory(Category c) =>
      state = state.copyWith(categoryId: c.id, clearError: true);

  void setNote(String value) => state = state.copyWith(note: value);

  void setSplits(List<ExpenseSplitDraft> splits) =>
      state = state.copyWith(splits: splits, clearError: true);

  /// Resets to a clean slate. Used after "Add Another".
  void reset() {
    _idempotencyKey = const Uuid().v4();
    state = const AddExpenseState();
  }

  Future<void> save() async {
    if (!state.canSave) return;

    final categories = ref.read(categoriesViewProvider).value ?? const [];
    Category? category;
    for (final c in categories) {
      if (c.id == state.categoryId) {
        category = c;
        break;
      }
    }
    if (category == null) {
      state = state.copyWith(error: 'Pick a category');
      return;
    }

    state = state.copyWith(saving: true, clearError: true);
    try {
      // Offline-first: the write is queued and shown optimistically. The
      // SyncEngine performs the actual POST when the server is reachable.
      final tx = await ref
          .read(addExpenseRepositoryProvider)
          .createExpense(
            category: category,
            amount: AmountInput.parse(state.amount),
            note: state.note,
            splits: state.splits,
            idempotencyKey: _idempotencyKey,
          );
      _idempotencyKey = const Uuid().v4();
      state = state.copyWith(saving: false, saved: tx);
    } catch (_) {
      state = state.copyWith(
        saving: false,
        error: 'Could not save. Try again.',
      );
    }
  }
}

final addExpenseControllerProvider =
    NotifierProvider<AddExpenseController, AddExpenseState>(
      AddExpenseController.new,
    );
