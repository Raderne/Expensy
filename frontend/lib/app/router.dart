import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/add_expense/presentation/add_expense_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/income/presentation/income_sources_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/recurring_confirmations/presentation/postponed_occurrences_screen.dart';
import '../features/recurring_expenses/presentation/recurring_expenses_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'app_shell.dart';

NavTab _tabForLocation(String location) {
  if (location.startsWith('/add')) return NavTab.add;
  if (location.startsWith('/transactions')) return NavTab.transactions;
  if (location.startsWith('/analytics')) return NavTab.analytics;
  if (location.startsWith('/profile')) return NavTab.profile;
  return NavTab.home;
}

const _authPaths = {'/login', '/signup', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading || !auth.hasValue) return null;
      final value = auth.value!;
      final loc = state.matchedLocation;
      final inAuth = _authPaths.contains(loc);

      if (value is AuthAuthenticated) {
        return inAuth ? '/' : null;
      }
      if (value is AuthUnauthenticated) {
        return inAuth ? null : '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (_, _) => const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (_, _) => const NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      // Add Expense lives OUTSIDE the shell so it covers the bottom nav and
      // presents as a full-height modal that slides up from the bottom.
      GoRoute(
        path: '/add',
        name: 'add',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          child: const AddExpenseScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final active = _tabForLocation(state.matchedLocation);
          return AppShell(active: active, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: TransactionsScreen()),
          ),
          GoRoute(
            path: '/postponed',
            name: 'postponed',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: PostponedOccurrencesScreen()),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ProfileScreen()),
            routes: [
              GoRoute(
                path: 'income-sources',
                name: 'income-sources',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: IncomeSourcesScreen()),
              ),
              GoRoute(
                path: 'recurring-expenses',
                name: 'recurring-expenses',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: RecurringExpensesScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's [authControllerProvider] state changes into a
/// [Listenable] that go_router's [GoRouter.refreshListenable] understands.
class _AuthRouterRefresh extends ChangeNotifier {
  late final ProviderSubscription<Object?> _sub;

  _AuthRouterRefresh(Ref ref) {
    _sub = ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
