import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/add_expense/presentation/add_expense_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'app_shell.dart';

NavTab _tabForLocation(String location) {
  if (location.startsWith('/add')) return NavTab.add;
  if (location.startsWith('/transactions')) return NavTab.transactions;
  if (location.startsWith('/analytics')) return NavTab.analytics;
  return NavTab.home;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final active = _tabForLocation(state.matchedLocation);
          return AppShell(active: active, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (_, _) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/add',
            name: 'add',
            pageBuilder: (_, _) => const NoTransitionPage(child: AddExpenseScreen()),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (_, _) => const NoTransitionPage(child: TransactionsScreen()),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (_, _) => const NoTransitionPage(child: AnalyticsScreen()),
          ),
        ],
      ),
    ],
  );
});
