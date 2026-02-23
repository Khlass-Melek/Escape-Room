import 'package:escape_room_admin/features/auth/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Represents an action done by or affecting a sub-admin.
class AdminLog {
  final String id;
  final String adminId;
  final String action;
  final DateTime timestamp;

  const AdminLog({
    required this.id,
    required this.adminId,
    required this.action,
    required this.timestamp,
  });
}

class SubAdminState {
  final List<User> subAdmins;
  final List<AdminLog> logs;

  const SubAdminState({
    this.subAdmins = const [],
    this.logs = const [],
  });

  SubAdminState copyWith({
    List<User>? subAdmins,
    List<AdminLog>? logs,
  }) {
    return SubAdminState(
      subAdmins: subAdmins ?? this.subAdmins,
      logs: logs ?? this.logs,
    );
  }
}

class SubAdminNotifier extends Notifier<SubAdminState> {
  final Uuid _uuid = const Uuid();

  @override
  SubAdminState build() {
    return SubAdminState(
      subAdmins: [
        const User(
          id: 'initial_gm_1',
          username: 'Alice (Game Master)',
          role: 'game_master',
        ),
        const User(
          id: 'initial_sous_1',
          username: 'Bob (Sous Admin)',
          role: 'sous_admin',
        ),
      ],
      logs: [
        AdminLog(
          id: _uuid.v4(),
          adminId: 'initial_sous_1',
          action: 'Compte créé par Super Admin',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        AdminLog(
          id: _uuid.v4(),
          adminId: 'initial_sous_1',
          action: 'Privilèges modifiés (Ajout accès Scénarios)',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    );
  }

  void addSubAdmin(String username, String role) {
    final newUser = User(
      id: _uuid.v4(),
      username: username,
      role: role,
    );
    
    final newLog = AdminLog(
      id: _uuid.v4(),
      adminId: newUser.id,
      action: 'Compte créé.',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      subAdmins: [...state.subAdmins, newUser],
      logs: [...state.logs, newLog],
    );
  }

  void updateSubAdmin(String id, String newUsername, String newRole) {
    final updatedAdmins = state.subAdmins.map((user) {
      if (user.id == id) {
        return user.copyWith(username: newUsername, role: newRole);
      }
      return user;
    }).toList();

    final newLog = AdminLog(
      id: _uuid.v4(),
      adminId: id,
      action: 'Profil ou privilèges mis à jour (Nouveau rôle: \$newRole).',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      subAdmins: updatedAdmins,
      logs: [...state.logs, newLog],
    );
  }

  void deleteSubAdmin(String id) {
    final updatedAdmins = state.subAdmins.where((user) => user.id != id).toList();
    // Keep logs for history, but remove the user

    state = state.copyWith(subAdmins: updatedAdmins);
  }

  List<AdminLog> getLogsForAdmin(String adminId) {
    return state.logs.where((log) => log.adminId == adminId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

final subAdminProvider = NotifierProvider<SubAdminNotifier, SubAdminState>(() {
  return SubAdminNotifier();
});
