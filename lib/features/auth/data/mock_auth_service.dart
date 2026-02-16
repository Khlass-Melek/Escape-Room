
import 'package:escape_room_admin/features/auth/domain/models/user.dart';

class MockAuthService {
  Future<User?> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (username.toLowerCase() == 'admin' && password == 'theroom2024') {
      return const User(
        id: '1',
        username: 'Admin',
        role: 'super_admin',
        profilePicture: 'https://i.pravatar.cc/150?u=admin',
      );
    }
    
    if (username.toLowerCase() == 'gm' && password == 'gamemaster') {
       return const User(
        id: '2',
        username: 'Game Master',
        role: 'game_master',
      );
    }

    return null; // Login failed
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
