import 'package:escape_room_admin/features/auth/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

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

  factory AdminLog.fromDb(Map<String, dynamic> row) {
    return AdminLog(
      id: row['id'].toString(),
      adminId: row['user_id']?.toString() ?? '',
      action: row['event_type'] ?? 'Action Inconnue',
      timestamp: DateTime.tryParse(row['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
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

class SubAdminNotifier extends AsyncNotifier<SubAdminState> {
  final _supabase = supa.Supabase.instance.client;

  @override
  Future<SubAdminState> build() async {
    return _fetchData();
  }

  Future<SubAdminState> _fetchData() async {
    // Fetch users except super_admin
    final usersResp = await _supabase
        .from('users')
        .select()
        .neq('role', 'super_admin')
        .order('created_at');

    final subAdmins = usersResp.map((row) => User(
          id: row['id'].toString(),
          username: row['email']?.toString() ?? 'Sans Email',
          role: row['role']?.toString() ?? 'viewer',
        )).toList();

    // Fetch logs representing actions on these admins
    // We leverage event_logs with a special severity 'ADMIN_LOG' to avoid colliding with game events
    final logsResp = await _supabase
        .from('event_logs')
        .select()
        .eq('severity', 'ADMIN_LOG')
        .order('timestamp', ascending: false);

    final logs = logsResp.map((row) => AdminLog.fromDb(row)).toList();

    return SubAdminState(subAdmins: subAdmins, logs: logs);
  }

  Future<void> addSubAdmin(String username, String role) async {
    state = const AsyncValue.loading();
    try {
      final String tempPassword = 'password123'; // Default password
      final newUserResp = await _supabase.from('users').insert({
        'email': username,
        'role': role,
        'password': tempPassword, // Hardcoded for simplified admin flow
      }).select().single();

      final userId = newUserResp['id'];

      await _supabase.from('event_logs').insert({
        'user_id': userId,
        'event_type': 'Compte créé.',
        'severity': 'ADMIN_LOG',
        'payload': {'action': 'CREATE', 'role': role}
      });

      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateSubAdmin(String id, String newUsername, String newRole) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('users').update({
        'email': newUsername,
        'role': newRole,
      }).eq('id', id);

      await _supabase.from('event_logs').insert({
        'user_id': id,
        'event_type': 'Profil ou privilèges mis à jour (Nouveau rôle: \$newRole).',
        'severity': 'ADMIN_LOG',
        'payload': {'action': 'UPDATE', 'role': newRole}
      });

      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteSubAdmin(String id) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('users').delete().eq('id', id);
      // event_logs have ON DELETE SET NULL for user_id, 
      // but to keep trace, we could insert a log before deleting if desired.
      
      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  List<AdminLog> getLogsForAdmin(String adminId) {
    if (!state.hasValue) return [];
    return state.value!.logs.where((log) => log.adminId == adminId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

final subAdminProvider = AsyncNotifierProvider<SubAdminNotifier, SubAdminState>(() {
  return SubAdminNotifier();
});
