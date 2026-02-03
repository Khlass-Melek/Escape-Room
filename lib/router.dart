import 'package:go_router/go_router.dart';

import 'package:escape_room_admin/features/auth/presentation/login_page.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/scenario_selection_page.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/dashboard_page.dart';

// TODO: Replace with real auth check (Riverpod, Bloc, SharedPreferences, etc.)
// In router.dart (top level)
bool _isLoggedIn = false;

bool get isLoggedIn => _isLoggedIn;

void setLoggedIn(bool value) {
  _isLoggedIn = value;
}// temporary – will be replaced later

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final loggedIn = isLoggedIn;
    final goingToLogin = state.uri.path == '/login';

    if (!loggedIn && !goingToLogin) {
      return '/login';
    }

    if (loggedIn && goingToLogin) {
      return '/select-scenario';
    }

    return null;
  },
  routes: [
   GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/select-scenario',
      builder: (context, state) => const ScenarioSelectionPage(),
    ),
    GoRoute(
      path: '/dashboard/:scenarioId',
      builder: (context, state) {
        final scenarioId = state.pathParameters['scenarioId']!;
        return DashboardPage(scenarioId: scenarioId);
      },
    ),
  ],
);