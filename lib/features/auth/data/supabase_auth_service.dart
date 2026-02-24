import 'package:escape_room_admin/features/auth/domain/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseAuthService {
  final _supabase = supa.Supabase.instance.client;

  Future<User?> login(String email, String password) async {
    try {
      // Direct query to the public 'users' table using email and password
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        // Update last login
        await _supabase
            .from('users')
            .update({'last_login': DateTime.now().toIso8601String()})
            .eq('id', response['id']);

        return User(
          id: response['id'].toString(),
          username: response['email'].toString(), // We use email as the identity
          role: response['role'].toString(),
        );
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    // For manual public.users authentication, logout is just local state clearing
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
