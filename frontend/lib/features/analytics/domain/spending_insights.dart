import 'package:flutter/foundation.dart';

/// How a single insight reads: a good sign, something to watch, or neutral.
enum InsightSentiment { positive, warning, neutral }

InsightSentiment _sentimentFrom(String? raw) {
  switch (raw) {
    case 'positive':
      return InsightSentiment.positive;
    case 'warning':
      return InsightSentiment.warning;
    default:
      return InsightSentiment.neutral;
  }
}

/// One quantified observation about the month.
@immutable
class Insight {
  final InsightSentiment sentiment;
  final String title;
  final String detail;

  const Insight({
    required this.sentiment,
    required this.title,
    required this.detail,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
    sentiment: _sentimentFrom(json['sentiment'] as String?),
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
  );
}

/// AI-generated read-out of a user's finances for one month, computed by the
/// backend from transactions, budget, trend, and recurring items
/// (see `insightsService.getInsights`).
@immutable
class SpendingInsights {
  final String headline;
  final String summary;
  final List<Insight> insights;
  final List<String> suggestions;

  /// The month's savings rate (net ÷ income × 100); null when income is zero.
  final double? savingsRatePct;

  /// The `YYYY-MM` month these insights describe.
  final String month;

  /// When this read-out was generated server-side.
  final DateTime generatedAt;

  const SpendingInsights({
    required this.headline,
    required this.summary,
    required this.insights,
    required this.suggestions,
    required this.savingsRatePct,
    required this.month,
    required this.generatedAt,
  });

  factory SpendingInsights.fromJson(Map<String, dynamic> json) =>
      SpendingInsights(
        headline: json['headline'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        insights:
            (json['insights'] as List<dynamic>?)
                ?.map((e) => Insight.fromJson(e as Map<String, dynamic>))
                .toList(growable: false) ??
            const [],
        suggestions:
            (json['suggestions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
        savingsRatePct: (json['savingsRatePct'] as num?)?.toDouble(),
        month: json['month'] as String? ?? '',
        generatedAt: json['generatedAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['generatedAt'] as String).toLocal(),
      );
}
