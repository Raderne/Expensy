import 'package:flutter/foundation.dart';

/// A single contact's share of an expense being composed in the UI. Serialized
/// into the `splits` array of a `POST /transactions` body.
@immutable
class ExpenseSplitDraft {
  final String contactId;
  final double owedAmount;

  const ExpenseSplitDraft({required this.contactId, required this.owedAmount});

  Map<String, dynamic> toJson() => {'contactId': contactId, 'owedAmount': owedAmount};

  ExpenseSplitDraft copyWith({double? owedAmount}) =>
      ExpenseSplitDraft(contactId: contactId, owedAmount: owedAmount ?? this.owedAmount);
}

/// Sum of all contacts' owed shares (i.e. the part NOT paid by the user).
double totalOwed(List<ExpenseSplitDraft> splits) =>
    splits.fold(0.0, (sum, s) => sum + s.owedAmount);
