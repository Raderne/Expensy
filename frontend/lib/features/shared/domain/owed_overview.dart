import 'package:flutter/foundation.dart';

/// A single repayment recorded against a split.
@immutable
class ReimbursementEntry {
  final String id;
  final double amount;
  final DateTime occurredAt;

  const ReimbursementEntry({
    required this.id,
    required this.amount,
    required this.occurredAt,
  });

  factory ReimbursementEntry.fromJson(Map<String, dynamic> json) => ReimbursementEntry(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
  );
}

/// One outstanding split (a contact's share of a single expense) with progress
/// and repayment history.
@immutable
class OwedSplit {
  final String splitId;
  final String expenseId;
  final String label;
  final DateTime occurredAt;
  final String categoryKey;
  final String categoryColor;
  final double owedAmount;
  final double settledAmount;
  final double remaining;
  final String status; // OWED | PARTIAL | SETTLED
  final List<ReimbursementEntry> reimbursements;

  const OwedSplit({
    required this.splitId,
    required this.expenseId,
    required this.label,
    required this.occurredAt,
    required this.categoryKey,
    required this.categoryColor,
    required this.owedAmount,
    required this.settledAmount,
    required this.remaining,
    required this.status,
    required this.reimbursements,
  });

  factory OwedSplit.fromJson(Map<String, dynamic> json) => OwedSplit(
    splitId: json['splitId'] as String,
    expenseId: json['expenseId'] as String,
    label: json['label'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
    categoryKey: json['categoryKey'] as String,
    categoryColor: json['categoryColor'] as String,
    owedAmount: (json['owedAmount'] as num).toDouble(),
    settledAmount: (json['settledAmount'] as num).toDouble(),
    remaining: (json['remaining'] as num).toDouble(),
    status: json['status'] as String,
    reimbursements: (json['reimbursements'] as List<dynamic>)
        .map((e) => ReimbursementEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// All a contact's outstanding splits plus their total owed.
@immutable
class OwedContact {
  final String contactId;
  final String contactName;
  final String? contactColor;
  final double outstanding;
  final List<OwedSplit> splits;

  const OwedContact({
    required this.contactId,
    required this.contactName,
    required this.contactColor,
    required this.outstanding,
    required this.splits,
  });

  factory OwedContact.fromJson(Map<String, dynamic> json) => OwedContact(
    contactId: json['contactId'] as String,
    contactName: json['contactName'] as String,
    contactColor: json['contactColor'] as String?,
    outstanding: (json['outstanding'] as num).toDouble(),
    splits: (json['splits'] as List<dynamic>)
        .map((e) => OwedSplit.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

@immutable
class OwedOverview {
  final double totalOutstanding;
  final List<OwedContact> contacts;

  const OwedOverview({required this.totalOutstanding, required this.contacts});

  factory OwedOverview.fromJson(Map<String, dynamic> json) => OwedOverview(
    totalOutstanding: (json['totalOutstanding'] as num).toDouble(),
    contacts: (json['contacts'] as List<dynamic>)
        .map((e) => OwedContact.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static const empty = OwedOverview(totalOutstanding: 0, contacts: []);
}
