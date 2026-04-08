import 'package:uuid/uuid.dart';

class GameReport {
  final String id;
  final String scenarioId;
  final String? sessionId;
  final int percentageCompleted;
  final int timePlayedMinutes;
  final bool isSuccess;
  final int cluesUsed;
  final int playerCount;
  final String? gamemasterNotes;
  final DateTime createdAt;
  final String status; // 'pending' or 'completed'

  GameReport({
    String? id,
    required this.scenarioId,
    this.sessionId,
    required this.percentageCompleted,
    required this.timePlayedMinutes,
    required this.isSuccess,
    this.cluesUsed = 0,
    this.playerCount = 0,
    this.gamemasterNotes,
    DateTime? createdAt,
    this.status = 'completed',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory GameReport.fromJson(Map<String, dynamic> json) {
    return GameReport(
      id: json['id'],
      scenarioId: json['scenario_id'],
      sessionId: json['session_id'],
      percentageCompleted: json['percentage_completed'] ?? 0,
      timePlayedMinutes: json['time_played_minutes'] ?? 0,
      isSuccess: json['is_success'] ?? false,
      cluesUsed: json['clues_used'] ?? 0,
      playerCount: json['player_count'] ?? 0,
      gamemasterNotes: json['gamemaster_notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      status: json['report_status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario_id': scenarioId,
      'session_id': sessionId,
      'percentage_completed': percentageCompleted,
      'time_played_minutes': timePlayedMinutes,
      'is_success': isSuccess,
      'clues_used': cluesUsed,
      'player_count': playerCount,
      'gamemaster_notes': gamemasterNotes,
      'created_at': createdAt.toIso8601String(),
      'report_status': status,
    };
  }
}
