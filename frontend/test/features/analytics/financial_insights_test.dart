import 'dart:async';

import 'package:dio/dio.dart';
import 'package:expensy/core/cache/http_cache.dart';
import 'package:expensy/features/analytics/application/analytics_insights_controller.dart';
import 'package:expensy/features/analytics/data/analytics_repository.dart';
import 'package:expensy/features/analytics/domain/financial_insights.dart';
import 'package:expensy/features/analytics/presentation/financial_insights_screen.dart';
import 'package:expensy/features/analytics/presentation/widgets/ai_insights_card.dart';
import 'package:expensy/features/analytics/presentation/widgets/insights_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MemoryCache implements HttpCache {
  @override
  Future<void> clear() async {}

  @override
  Future<Map<String, dynamic>?> read(String key) async => null;

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {}
}

class _Repo extends AnalyticsRepository {
  _Repo() : super(Dio(), _MemoryCache());

  FinancialInsightsReport? report;
  Object? error;
  bool? lastRefresh;
  int calls = 0;
  Completer<FinancialInsightsReport>? gate;

  @override
  Future<FinancialInsightsReport> getInsights({
    required String month,
    bool refresh = false,
  }) async {
    calls += 1;
    lastRefresh = refresh;
    final pending = gate;
    if (pending != null) return pending.future;
    if (error != null) throw error!;
    return report!;
  }
}

const _json = {
  'version': 2,
  'currencyCode': 'USD',
  'month': '2026-06',
  'generatedAt': '2026-06-15T12:00:00.000Z',
  'aiStatus': 'generated',
  'headline': 'You kept 33% of income.',
  'summary': 'Income covered spending.',
  'scorecard': {
    'income': 3000,
    'expenses': 2000,
    'net': 1000,
    'savingsRatePct': 33,
    'budgetAmount': 2400,
    'budgetPct': 83,
    'incomeChangePct': 0,
    'expenseChangePct': -10,
  },
  'trend': [
    {
      'month': '2026-05',
      'income': 3000,
      'expenses': 2200,
      'net': 800,
      'savingsRatePct': 27,
      'hasActivity': true,
    },
    {
      'month': '2026-06',
      'income': 3000,
      'expenses': 2000,
      'net': 1000,
      'savingsRatePct': 33,
      'hasActivity': true,
    },
  ],
  'categoryChanges': [
    {
      'categoryId': 'c1',
      'label': 'Food',
      'amount': 1200,
      'sharePct': 60,
      'baselineAmount': 400,
      'changePct': 200,
    },
  ],
  'commitments': {
    'recurringExpenseMonthly': 1200,
    'recurringIncomeMonthly': 3000,
    'coveragePct': 250,
    'upcoming': [
      {'label': 'Rent', 'amount': 1200, 'dueAt': '2026-06-20T00:00:00.000Z'},
    ],
  },
  'goalOutlook': [
    {
      'name': 'Trip',
      'savedAmount': 200,
      'targetAmount': 1000,
      'progressPct': 20,
      'targetDate': null,
    },
  ],
  'dataCoverage': {
    'historyMonths': 4,
    'windowMonths': 6,
    'hasBudget': true,
    'hasRecurringIncome': true,
    'hasRecurringExpenses': true,
    'hasGoals': true,
    'limitations': ['Educational budgeting guidance only.'],
  },
  'insights': [
    {
      'factId': 'savings_rate',
      'sentiment': 'positive',
      'title': 'Saving',
      'detail': 'Net is positive.',
      'evidence': 'Savings rate is 33%.',
    },
  ],
  'actions': [
    {
      'candidateId': 'review_category',
      'target': 'transactions',
      'categoryId': 'c1',
      'title': 'Review Food',
      'detail': 'Food is 60% of spending.',
      'evidence': 'Food is 1200 USD.',
    },
    {
      'candidateId': 'mystery',
      'target': 'wire_transfer',
      'categoryId': null,
      'title': 'Ignore me',
      'detail': 'Not an allowlisted destination.',
      'evidence': 'nope',
    },
  ],
  'notes': [
    {'factId': 'goals', 'text': 'The trip goal is still open.'},
  ],
};

FinancialInsightsReport _report({InsightAiStatus? status}) {
  final parsed = FinancialInsightsReport.fromJson(
    Map<String, dynamic>.from(_json),
  );
  if (status == null || status == parsed.aiStatus) return parsed;
  return FinancialInsightsReport(
    version: parsed.version,
    currencyCode: parsed.currencyCode,
    month: parsed.month,
    generatedAt: parsed.generatedAt,
    aiStatus: status,
    headline: parsed.headline,
    summary: parsed.summary,
    scorecard: parsed.scorecard,
    trend: parsed.trend,
    categoryChanges: parsed.categoryChanges,
    commitments: parsed.commitments,
    goalOutlook: parsed.goalOutlook,
    dataCoverage: parsed.dataCoverage,
    insights: parsed.insights,
    actions: parsed.actions,
    notes: parsed.notes,
  );
}

void main() {
  setUpAll(() => registerFallbackValue(RequestOptions(path: '/')));

  group('FinancialInsightsReport', () {
    test('parses the report and drops unknown action targets', () {
      final report = FinancialInsightsReport.fromJson(
        Map<String, dynamic>.from(_json),
      );
      expect(report.version, 2);
      expect(report.scorecard.savingsRatePct, 33);
      expect(report.actions, hasLength(1));
      expect(report.actions.single.target, InsightActionTarget.transactions);
      expect(insightPath(report.actions.single.target), '/transactions');
      expect(insightPath(InsightActionTarget.budget), '/profile');
      expect(
        insightsFreshnessLabel(
          DateTime.now().subtract(const Duration(minutes: 5)),
          DateTime.now(),
        ),
        'Generated 5 min ago',
      );
    });
  });

  group('AnalyticsRepository.getInsights', () {
    late _MockDio dio;
    late AnalyticsRepository repo;

    setUp(() {
      dio = _MockDio();
      repo = AnalyticsRepository(dio, _MemoryCache());
    });

    test('parses a 200 response', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/analytics/insights'),
          statusCode: 200,
          data: {'insights': _json},
        ),
      );

      final report = await repo.getInsights(month: '2026-06');
      expect(report.headline, 'You kept 33% of income.');
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/analytics/insights',
          queryParameters: {'month': '2026-06'},
        ),
      ).called(1);
    });

    test('sends refresh=true and maps insufficient data', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/analytics/insights'),
          statusCode: 422,
          data: {'code': 'INSUFFICIENT_DATA', 'title': 'No data'},
        ),
      );

      await expectLater(
        () => repo.getInsights(month: '2026-06', refresh: true),
        throwsA(
          isA<AnalyticsApiException>().having(
            (e) => e.code,
            'code',
            'INSUFFICIENT_DATA',
          ),
        ),
      );
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/analytics/insights',
          queryParameters: {'month': '2026-06', 'refresh': 'true'},
        ),
      ).called(1);
    });
  });

  group('InsightsController', () {
    late _Repo repo;

    setUp(() => repo = _Repo());

    ProviderContainer container() {
      final result = ProviderContainer(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(result.dispose);
      return result;
    }

    test(
      'stays idle until generate, then keeps the report while refreshing',
      () async {
        repo.report = _report();
        final box = container();
        final provider = analyticsInsightsControllerProvider('2026-06');
        expect(box.read(provider), isNull);

        await box.read(provider.notifier).generate();
        expect(
          box.read(provider)?.asData?.value.headline,
          'You kept 33% of income.',
        );
        expect(repo.lastRefresh, isFalse);

        repo.gate = Completer<FinancialInsightsReport>();
        final pending = box.read(provider.notifier).generate(refresh: true);
        expect(box.read(provider)?.isLoading, isTrue);
        expect(box.read(provider)?.value?.headline, 'You kept 33% of income.');

        repo.gate!.complete(_report());
        await pending;
        expect(repo.lastRefresh, isTrue);
        expect(box.read(provider)?.hasError, isFalse);
      },
    );

    test('surfaces insufficient data without a report', () async {
      repo.error = const AnalyticsApiException(
        status: 422,
        code: 'INSUFFICIENT_DATA',
        message: 'No data',
      );
      final box = container();
      await box
          .read(analyticsInsightsControllerProvider('2026-06').notifier)
          .generate();
      final state = box.read(analyticsInsightsControllerProvider('2026-06'));
      expect(state?.hasError, isTrue);
      expect((state?.error as AnalyticsApiException).code, 'INSUFFICIENT_DATA');
    });
  });

  group('insights UI', () {
    late _Repo repo;

    setUp(() => repo = _Repo()..report = _report());

    Future<void> pumpCard(WidgetTester tester) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: AiInsightsCard(month: '2026-06')),
          ),
          GoRoute(
            path: '/analytics/insights/:month',
            builder: (_, _) => const Scaffold(body: Text('opened-report')),
          ),
        ],
      );
      addTearDown(router.dispose);
      return tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    testWidgets('idle card explains coverage and privacy before generation', (
      tester,
    ) async {
      await pumpCard(tester);
      expect(find.text('Generate insights'), findsOneWidget);
      expect(find.textContaining('Google Gemini'), findsOneWidget);
      expect(find.textContaining('five before it'), findsOneWidget);
      expect(repo.calls, 0);
    });

    testWidgets('opening the report shows loading, then the full review', (
      tester,
    ) async {
      repo.gate = Completer<FinancialInsightsReport>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: FinancialInsightsScreen(month: '2026-06'),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(
          'Reviewing trends, budget, goals, and recurring commitments…',
        ),
        findsOneWidget,
      );

      repo.gate!.complete(_report());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('You kept 33% of income.'), findsOneWidget);
      expect(find.text('Based on 4 months of history'), findsOneWidget);
      expect(find.text('Good sign'), findsOneWidget);
      expect(find.text('View transactions'), findsOneWidget);
      expect(find.byKey(const Key('insights-two-column')), findsOneWidget);
    });

    testWidgets('insufficient data explains the next step', (tester) async {
      repo.error = const AnalyticsApiException(
        status: 422,
        code: 'INSUFFICIENT_DATA',
        message: 'No data',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: FinancialInsightsScreen(month: '2026-06'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Not enough to analyse yet'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('unavailable commentary still shows calculated figures', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InsightsReportBody(
                report: _report(status: InsightAiStatus.unavailable),
                wide: false,
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('You kept 33% of income.'), findsOneWidget);
      expect(find.textContaining('commentary is unavailable'), findsWidgets);
      expect(find.text('\$3,000'), findsWidgets);
    });

    testWidgets(
      'wide layout uses two columns and large text does not overflow',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(900, 1400),
              textScaler: TextScaler.linear(2),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: InsightsReportBody(
                    report: _report(),
                    wide: true,
                    onOpen: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byKey(const Key('insights-two-column')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('trend and findings are exposed to semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InsightsReportBody(
                report: _report(),
                wide: false,
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp(r'Net by month')), findsOneWidget);
      expect(find.text('Watch'), findsNothing);
      expect(find.text('Good sign'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('refresh keeps the report and asks for a recompute', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: FinancialInsightsScreen(month: '2026-06'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('You kept 33% of income.'), findsOneWidget);

      repo.gate = Completer<FinancialInsightsReport>();
      await tester.tap(find.text('Refresh analysis'));
      await tester.pump();
      expect(find.text('You kept 33% of income.'), findsOneWidget);
      expect(find.text('Refreshing…'), findsOneWidget);
      expect(repo.lastRefresh, isTrue);

      repo.gate!.complete(_report());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
    });
  });
}
