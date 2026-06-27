import 'package:dio/dio.dart';
import 'package:expensy/features/auth/application/auth_controller.dart';
import 'package:expensy/features/auth/domain/auth_state.dart';
import 'package:expensy/features/auth/domain/auth_user.dart';
import 'package:expensy/features/goals/application/goal_estimate_controller.dart';
import 'package:expensy/features/goals/data/goals_repository.dart';
import 'package:expensy/features/goals/domain/goal_estimate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _resp(int status, Map<String, dynamic> data) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/me/goals/g1/estimate'),
      statusCode: status,
      data: data,
    );

const _estimateJson = {
  'reachable': true,
  'estimatedMonths': 8,
  'estimatedDate': '2027-02-01T00:00:00.000Z',
  'monthlyNetSavings': 1000.0,
  'confidence': 'high',
  'summary': 'On pace to finish in about 8 months.',
  'tips': ['Trim Food spending'],
  'generatedAt': '2026-06-27T00:00:00.000Z',
};

class _FakeAuthController extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthAuthenticated(AuthUser(id: 'u1', email: 'a@b.c', name: 'A'));
}

class _FakeGoalsRepository extends GoalsRepository {
  _FakeGoalsRepository() : super(_MockDio());

  GoalEstimate? result;
  Object? error;
  bool? lastRefresh;

  @override
  Future<GoalEstimate> getEstimate(String id, {bool refresh = false}) async {
    lastRefresh = refresh;
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  setUpAll(() => registerFallbackValue(RequestOptions(path: '/')));

  group('GoalsRepository.getEstimate', () {
    late _MockDio dio;
    late GoalsRepository repo;

    setUp(() {
      dio = _MockDio();
      repo = GoalsRepository(dio);
    });

    test('parses a 200 response into a GoalEstimate', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _resp(200, {'estimate': _estimateJson}));

      final estimate = await repo.getEstimate('g1');

      expect(estimate.estimatedMonths, 8);
      expect(estimate.confidence, 'high');
      expect(estimate.tips, ['Trim Food spending']);
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/me/goals/g1/estimate',
          queryParameters: null,
        ),
      ).called(1);
    });

    test('sends refresh=true when forcing a recompute', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _resp(200, {'estimate': _estimateJson}));

      await repo.getEstimate('g1', refresh: true);

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/me/goals/g1/estimate',
          queryParameters: {'refresh': 'true'},
        ),
      ).called(1);
    });

    test('maps 422 INSUFFICIENT_DATA to a GoalsApiException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async =>
            _resp(422, {'code': 'INSUFFICIENT_DATA', 'title': 'No data'}),
      );

      expect(
        () => repo.getEstimate('g1'),
        throwsA(
          isA<GoalsApiException>()
              .having((e) => e.code, 'code', 'INSUFFICIENT_DATA')
              .having((e) => e.status, 'status', 422),
        ),
      );
    });

    test('maps 503 AI_UNAVAILABLE to a GoalsApiException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async =>
            _resp(503, {'code': 'AI_UNAVAILABLE', 'title': 'Unavailable'}),
      );

      expect(
        () => repo.getEstimate('g1'),
        throwsA(
          isA<GoalsApiException>().having(
            (e) => e.code,
            'code',
            'AI_UNAVAILABLE',
          ),
        ),
      );
    });
  });

  group('GoalEstimateController', () {
    late _FakeGoalsRepository repo;

    ProviderContainer build() {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          goalsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() => repo = _FakeGoalsRepository());

    test('returns the repository estimate when authenticated', () async {
      repo.result = GoalEstimate.fromJson(Map.of(_estimateJson));
      final container = build();
      await container.read(authControllerProvider.future);

      final estimate = await container.read(
        goalEstimateControllerProvider('g1').future,
      );

      expect(estimate.estimatedMonths, 8);
      expect(repo.lastRefresh, false);
    });

    test('surfaces an insufficient-data error', () async {
      repo.error = const GoalsApiException(
        status: 422,
        code: 'INSUFFICIENT_DATA',
        message: 'No data',
      );
      final container = build();
      await container.read(authControllerProvider.future);

      await expectLater(
        container.read(goalEstimateControllerProvider('g1').future),
        throwsA(
          isA<GoalsApiException>().having(
            (e) => e.code,
            'code',
            'INSUFFICIENT_DATA',
          ),
        ),
      );
    });
  });
}
