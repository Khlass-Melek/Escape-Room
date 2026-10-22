import 'package:escape_room_admin/features/auth/presentation/login_page.dart';
import 'package:escape_room_admin/features/auth/presentation/providers/auth_provider.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/scenarios_list_page.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:escape_room_admin/features/settings/presentation/pages/scenario_settings_page.dart';
import 'package:escape_room_admin/features/admin/presentation/pages/sub_admin_management_page.dart';
import 'package:escape_room_admin/features/admin/presentation/pages/enigma_management_page.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/pending_reports_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authProvider);
  final authState = authStateAsync.value ?? const AuthState();

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.isAuthenticated;
      final goingToLogin = state.uri.path == '/login';

      if (!loggedIn && !goingToLogin) {
        return '/login';
      }

      if (loggedIn && goingToLogin) {
        return '/dashboard-home';
      }

      if ((state.uri.path == '/admin/sub-admins' || state.uri.path == '/admin/enigmas') && authState.user?.role != 'super_admin') {
        return '/dashboard-home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard-home',
        builder: (context, state) => const DashboardHomePage(),
      ),
      GoRoute(
        path: '/scenarios',
        builder: (context, state) => const ScenariosListPage(),
      ),
      GoRoute(
        path: '/dashboard/:scenarioId',
        builder: (context, state) {
          final scenarioId = state.pathParameters['scenarioId']!;
          return DashboardPage(scenarioId: scenarioId);
        },
      ),
      GoRoute(
        path: '/settings/scenarios',
        builder: (context, state) => const ScenarioSettingsPage(),
      ),
      GoRoute(
        path: '/admin/sub-admins',
        builder: (context, state) => const SubAdminManagementPage(),
      ),
      GoRoute(
        path: '/admin/enigmas',
        builder: (context, state) => const EnigmaManagementPage(),
      ),
      GoRoute(
        path: '/reports/pending',
        builder: (context, state) => const PendingReportsPage(),
      ),
    ],
  );
});