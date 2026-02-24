
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_room_admin/features/auth/data/supabase_auth_service.dart';
import 'package:escape_room_admin/features/auth/domain/models/user.dart';

final authServiceProvider = Provider((ref) => SupabaseAuthService());

@immutable
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return const AuthState();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(username, password);
      
      if (user != null) {
        state = AsyncValue.data(AuthState(user: user));
      } else {
        state = const AsyncValue.data(AuthState(error: 'Invalid username or password'));
      }
    } catch (e) {
      state = const AsyncValue.data(AuthState(error: 'An unexpected error occurred'));
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncValue.data(AuthState());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
