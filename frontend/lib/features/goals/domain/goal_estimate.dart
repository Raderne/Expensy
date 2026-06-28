import 'package:flutter/foundation.dart';

/// AI-generated forecast of how long a goal will take to reach, computed by the
/// backend from the user's recent spending/income (see `goalService.estimate`).
@immutable
class GoalEstimate {
  /// Whether the goal is reachable at the user's current net-savings pace.
  final bool reachable;

  /// Whole months to reach the goal from now; null when [reachable] is false.
  final int? estimatedMonths;

  /// Projected completion date; null when not reachable.
  final DateTime? estimatedDate;

  /// Average monthly net savings the estimate is based on.
  final double monthlyNetSavings;

  /// `low` | `medium` | `high` — how reliable the estimate is.
  final String confidence;

  /// One- or two-sentence plain-language explanation.
  final String summary;

  /// Up to three concrete suggestions to reach the goal faster.
  final List<String> tips;

  /// When this estimate was generated server-side.
  final DateTime generatedAt;

  const GoalEstimate({
    required this.reachable,
    required this.estimatedMonths,
    required this.estimatedDate,
    required this.monthlyNetSavings,
    required this.confidence,
    required this.summary,
    required this.tips,
    required this.generatedAt,
  });

  factory GoalEstimate.fromJson(Map<String, dynamic> json) => GoalEstimate(
    reachable: json['reachable'] as bool? ?? false,
    estimatedMonths: (json['estimatedMonths'] as num?)?.toInt(),
    estimatedDate: json['estimatedDate'] == null
        ? null
        : DateTime.parse(json['estimatedDate'] as String).toLocal(),
    monthlyNetSavings: (json['monthlyNetSavings'] as num?)?.toDouble() ?? 0,
    confidence: json['confidence'] as String? ?? 'low',
    summary: json['summary'] as String? ?? '',
    tips:
        (json['tips'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const [],
    generatedAt: json['generatedAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['generatedAt'] as String).toLocal(),
  );
}
