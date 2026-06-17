import 'package:flutter/foundation.dart';

enum ShareType { amount, percent }

extension ShareTypeX on ShareType {
  String get wireValue => this == ShareType.amount ? 'AMOUNT' : 'PERCENT';
  static ShareType fromWire(String v) =>
      v == 'AMOUNT' ? ShareType.amount : ShareType.percent;
}

/// A contact's share template on a recurring rule, as composed in the UI and
/// sent in the `shares` array of the recurring-expense create/update body.
@immutable
class RecurringShareDraft {
  final String contactId;
  final ShareType shareType;
  final double shareValue;

  const RecurringShareDraft({
    required this.contactId,
    required this.shareType,
    required this.shareValue,
  });

  factory RecurringShareDraft.fromJson(Map<String, dynamic> json) => RecurringShareDraft(
    contactId: json['contactId'] as String,
    shareType: ShareTypeX.fromWire(json['shareType'] as String),
    shareValue: (json['shareValue'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'shareType': shareType.wireValue,
    'shareValue': shareValue,
  };

  RecurringShareDraft copyWith({ShareType? shareType, double? shareValue}) =>
      RecurringShareDraft(
        contactId: contactId,
        shareType: shareType ?? this.shareType,
        shareValue: shareValue ?? this.shareValue,
      );
}
