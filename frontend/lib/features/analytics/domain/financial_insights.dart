import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum InsightSentiment { positive, warning, neutral }

enum InsightAiStatus { generated, unavailable }

enum InsightActionTarget {
  transactions,
  recurringExpenses,
  incomeSources,
  goals,
  budget,
}

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

InsightActionTarget? _targetFrom(String? raw) {
  switch (raw) {
    case 'transactions':
      return InsightActionTarget.transactions;
    case 'recurring_expenses':
      return InsightActionTarget.recurringExpenses;
    case 'income_sources':
      return InsightActionTarget.incomeSources;
    case 'goals':
      return InsightActionTarget.goals;
    case 'budget':
      return InsightActionTarget.budget;
    default:
      return null;
  }
}

double _num(Object? value) => (value as num?)?.toDouble() ?? 0;

double? _optNum(Object? value) => (value as num?)?.toDouble();

List<Map<String, dynamic>> _maps(Object? value) =>
    (value as List<dynamic>?)
        ?.whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false) ??
    const [];

@immutable
class InsightScorecard {
  final double income;
  final double expenses;
  final double net;
  final double? savingsRatePct;
  final double? budgetAmount;
  final double? budgetPct;
  final double? incomeChangePct;
  final double? expenseChangePct;

  const InsightScorecard({
    required this.income,
    required this.expenses,
    required this.net,
    required this.savingsRatePct,
    required this.budgetAmount,
    required this.budgetPct,
    required this.incomeChangePct,
    required this.expenseChangePct,
  });

  factory InsightScorecard.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return InsightScorecard(
      income: _num(data['income']),
      expenses: _num(data['expenses']),
      net: _num(data['net']),
      savingsRatePct: _optNum(data['savingsRatePct']),
      budgetAmount: _optNum(data['budgetAmount']),
      budgetPct: _optNum(data['budgetPct']),
      incomeChangePct: _optNum(data['incomeChangePct']),
      expenseChangePct: _optNum(data['expenseChangePct']),
    );
  }
}

@immutable
class InsightTrendPoint {
  final String month;
  final double income;
  final double expenses;
  final double net;
  final double? savingsRatePct;
  final bool hasActivity;

  const InsightTrendPoint({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
    required this.savingsRatePct,
    required this.hasActivity,
  });

  factory InsightTrendPoint.fromJson(Map<String, dynamic> json) =>
      InsightTrendPoint(
        month: json['month'] as String? ?? '',
        income: _num(json['income']),
        expenses: _num(json['expenses']),
        net: _num(json['net']),
        savingsRatePct: _optNum(json['savingsRatePct']),
        hasActivity: json['hasActivity'] as bool? ?? false,
      );
}

@immutable
class InsightCategoryChange {
  final String categoryId;
  final String label;
  final double amount;
  final double sharePct;
  final double? baselineAmount;
  final double? changePct;

  const InsightCategoryChange({
    required this.categoryId,
    required this.label,
    required this.amount,
    required this.sharePct,
    required this.baselineAmount,
    required this.changePct,
  });

  factory InsightCategoryChange.fromJson(Map<String, dynamic> json) =>
      InsightCategoryChange(
        categoryId: json['categoryId'] as String? ?? '',
        label: json['label'] as String? ?? '',
        amount: _num(json['amount']),
        sharePct: _num(json['sharePct']),
        baselineAmount: _optNum(json['baselineAmount']),
        changePct: _optNum(json['changePct']),
      );
}

@immutable
class InsightUpcoming {
  final String label;
  final double amount;
  final String dueAt;

  const InsightUpcoming({
    required this.label,
    required this.amount,
    required this.dueAt,
  });

  factory InsightUpcoming.fromJson(Map<String, dynamic> json) =>
      InsightUpcoming(
        label: json['label'] as String? ?? '',
        amount: _num(json['amount']),
        dueAt: json['dueAt'] as String? ?? '',
      );
}

@immutable
class InsightCommitments {
  final double recurringExpenseMonthly;
  final double recurringIncomeMonthly;
  final double? coveragePct;
  final List<InsightUpcoming> upcoming;

  const InsightCommitments({
    required this.recurringExpenseMonthly,
    required this.recurringIncomeMonthly,
    required this.coveragePct,
    required this.upcoming,
  });

  factory InsightCommitments.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return InsightCommitments(
      recurringExpenseMonthly: _num(data['recurringExpenseMonthly']),
      recurringIncomeMonthly: _num(data['recurringIncomeMonthly']),
      coveragePct: _optNum(data['coveragePct']),
      upcoming: _maps(data['upcoming']).map(InsightUpcoming.fromJson).toList(),
    );
  }
}

@immutable
class InsightGoalOutlook {
  final String name;
  final double savedAmount;
  final double targetAmount;
  final double progressPct;
  final String? targetDate;

  const InsightGoalOutlook({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.progressPct,
    required this.targetDate,
  });

  factory InsightGoalOutlook.fromJson(Map<String, dynamic> json) =>
      InsightGoalOutlook(
        name: json['name'] as String? ?? '',
        savedAmount: _num(json['savedAmount']),
        targetAmount: _num(json['targetAmount']),
        progressPct: _num(json['progressPct']),
        targetDate: json['targetDate'] as String?,
      );
}

@immutable
class InsightCoverage {
  final int historyMonths;
  final int windowMonths;
  final bool hasBudget;
  final bool hasRecurringIncome;
  final bool hasRecurringExpenses;
  final bool hasGoals;
  final List<String> limitations;

  const InsightCoverage({
    required this.historyMonths,
    required this.windowMonths,
    required this.hasBudget,
    required this.hasRecurringIncome,
    required this.hasRecurringExpenses,
    required this.hasGoals,
    required this.limitations,
  });

  factory InsightCoverage.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return InsightCoverage(
      historyMonths: (data['historyMonths'] as num?)?.toInt() ?? 0,
      windowMonths: (data['windowMonths'] as num?)?.toInt() ?? 0,
      hasBudget: data['hasBudget'] as bool? ?? false,
      hasRecurringIncome: data['hasRecurringIncome'] as bool? ?? false,
      hasRecurringExpenses: data['hasRecurringExpenses'] as bool? ?? false,
      hasGoals: data['hasGoals'] as bool? ?? false,
      limitations:
          (data['limitations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}

@immutable
class InsightFinding {
  final String factId;
  final InsightSentiment sentiment;
  final String title;
  final String detail;
  final String evidence;

  const InsightFinding({
    required this.factId,
    required this.sentiment,
    required this.title,
    required this.detail,
    required this.evidence,
  });

  factory InsightFinding.fromJson(Map<String, dynamic> json) => InsightFinding(
    factId: json['factId'] as String? ?? '',
    sentiment: _sentimentFrom(json['sentiment'] as String?),
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
    evidence: json['evidence'] as String? ?? '',
  );
}

@immutable
class InsightAction {
  final String candidateId;
  final InsightActionTarget target;
  final String? categoryId;
  final String title;
  final String detail;
  final String evidence;

  const InsightAction({
    required this.candidateId,
    required this.target,
    required this.categoryId,
    required this.title,
    required this.detail,
    required this.evidence,
  });

  static InsightAction? fromJson(Map<String, dynamic> json) {
    final target = _targetFrom(json['target'] as String?);
    if (target == null) return null;
    return InsightAction(
      candidateId: json['candidateId'] as String? ?? '',
      target: target,
      categoryId: json['categoryId'] as String?,
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      evidence: json['evidence'] as String? ?? '',
    );
  }
}

@immutable
class InsightNote {
  final String factId;
  final String text;

  const InsightNote({required this.factId, required this.text});

  factory InsightNote.fromJson(Map<String, dynamic> json) => InsightNote(
    factId: json['factId'] as String? ?? '',
    text: json['text'] as String? ?? '',
  );
}

/// Versioned financial-health report. Money figures are server-calculated;
/// [headline], findings, and actions are commentary grounded in those figures.
@immutable
class FinancialInsightsReport {
  final int version;
  final String currencyCode;
  final String month;
  final DateTime generatedAt;
  final InsightAiStatus aiStatus;
  final String headline;
  final String summary;
  final InsightScorecard scorecard;
  final List<InsightTrendPoint> trend;
  final List<InsightCategoryChange> categoryChanges;
  final InsightCommitments commitments;
  final List<InsightGoalOutlook> goalOutlook;
  final InsightCoverage dataCoverage;
  final List<InsightFinding> insights;
  final List<InsightAction> actions;
  final List<InsightNote> notes;

  const FinancialInsightsReport({
    required this.version,
    required this.currencyCode,
    required this.month,
    required this.generatedAt,
    required this.aiStatus,
    required this.headline,
    required this.summary,
    required this.scorecard,
    required this.trend,
    required this.categoryChanges,
    required this.commitments,
    required this.goalOutlook,
    required this.dataCoverage,
    required this.insights,
    required this.actions,
    required this.notes,
  });

  bool get commentaryAvailable => aiStatus == InsightAiStatus.generated;

  factory FinancialInsightsReport.fromJson(Map<String, dynamic> json) =>
      FinancialInsightsReport(
        version: (json['version'] as num?)?.toInt() ?? 0,
        currencyCode: json['currencyCode'] as String? ?? 'USD',
        month: json['month'] as String? ?? '',
        generatedAt: json['generatedAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['generatedAt'] as String).toLocal(),
        aiStatus: json['aiStatus'] == 'generated'
            ? InsightAiStatus.generated
            : InsightAiStatus.unavailable,
        headline: json['headline'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        scorecard: InsightScorecard.fromJson(
          json['scorecard'] as Map<String, dynamic>?,
        ),
        trend: _maps(json['trend']).map(InsightTrendPoint.fromJson).toList(),
        categoryChanges: _maps(
          json['categoryChanges'],
        ).map(InsightCategoryChange.fromJson).toList(),
        commitments: InsightCommitments.fromJson(
          json['commitments'] as Map<String, dynamic>?,
        ),
        goalOutlook: _maps(
          json['goalOutlook'],
        ).map(InsightGoalOutlook.fromJson).toList(),
        dataCoverage: InsightCoverage.fromJson(
          json['dataCoverage'] as Map<String, dynamic>?,
        ),
        insights: _maps(json['insights']).map(InsightFinding.fromJson).toList(),
        actions: _maps(
          json['actions'],
        ).map(InsightAction.fromJson).whereType<InsightAction>().toList(),
        notes: _maps(json['notes']).map(InsightNote.fromJson).toList(),
      );
}

String insightPath(InsightActionTarget target) {
  switch (target) {
    case InsightActionTarget.transactions:
      return '/transactions';
    case InsightActionTarget.recurringExpenses:
      return '/profile/recurring-expenses';
    case InsightActionTarget.incomeSources:
      return '/profile/income-sources';
    case InsightActionTarget.goals:
      return '/profile/goals';
    case InsightActionTarget.budget:
      return '/profile';
  }
}

String insightDestinationLabel(InsightActionTarget target) {
  switch (target) {
    case InsightActionTarget.transactions:
      return 'View transactions';
    case InsightActionTarget.recurringExpenses:
      return 'Review recurring bills';
    case InsightActionTarget.incomeSources:
      return 'Review income';
    case InsightActionTarget.goals:
      return 'Open goals';
    case InsightActionTarget.budget:
      return 'Open budget';
  }
}

String insightsFreshnessLabel(DateTime generatedAt, DateTime now) {
  final diff = now.difference(generatedAt);
  if (diff.isNegative || diff.inMinutes < 1) return 'Generated just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'Generated $m min ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'Generated $h hr ago';
  }
  return 'Generated ${DateFormat('MMM d').format(generatedAt)}';
}

String formatInsightMoney(double amount, String currencyCode) {
  return NumberFormat.simpleCurrency(
    locale: 'en_US',
    name: currencyCode,
    decimalDigits: 0,
  ).format(amount);
}

final insightMonthPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
