import 'package:flutter/foundation.dart';

/// The currently-postponed occurrence for a recurring rule, surfaced on the rule
/// so the edit sheet can show "this cycle is postponed to …" and let the user
/// change or restore it. The recurrence schedule itself is unaffected.
@immutable
class PostponedInfo {
  final String id;

  /// The original schedule day this cycle belongs to (never moves).
  final DateTime scheduledFor;

  /// When the prompt will next appear (the postponed-to day).
  final DateTime dueAt;

  const PostponedInfo({
    required this.id,
    required this.scheduledFor,
    required this.dueAt,
  });

  factory PostponedInfo.fromJson(Map<String, dynamic> json) => PostponedInfo(
    id: json['id'] as String,
    scheduledFor: DateTime.parse(json['scheduledFor'] as String).toLocal(),
    dueAt: DateTime.parse(json['dueAt'] as String).toLocal(),
  );
}
