import 'package:escape_room_admin/models/game_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class GameReportNotifier extends AsyncNotifier<List<GameReport>> {
  final _supabase = supa.Supabase.instance.client;

  @override
  Future<List<GameReport>> build() async {
    return _fetchReports();
  }

  Future<List<GameReport>> _fetchReports() async {
    final resp = await _supabase.from('game_reports').select().order('created_at', ascending: false);
    return resp.map((row) => GameReport.fromJson(row)).toList();
  }

  Future<void> submitReport(GameReport report) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('game_reports').upsert(report.toJson());
      state = AsyncValue.data(await _fetchReports());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('game_reports').update({'report_status': status}).eq('id', id);
      state = AsyncValue.data(await _fetchReports());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final gameReportProvider = AsyncNotifierProvider<GameReportNotifier, List<GameReport>>(() {
  return GameReportNotifier();
});

/// Aggregate stats per scenario — enriched with more metrics + dynamic difficulty
final scenarioStatsProvider = Provider.family<Map<String, dynamic>, String>((ref, scenarioId) {
  final reportsAsync = ref.watch(gameReportProvider);

  return reportsAsync.when(
    data: (reports) {
      final all = reports.where((r) => r.scenarioId == scenarioId).toList();
      final completed = all.where((r) => r.status == 'completed').toList();

      if (completed.isEmpty) {
        return {
          'successRate': 0.0,
          'avgTime': '--:--',
          'totalGames': 0,
          'successCount': 0,
          'failCount': 0,
          'avgClues': 0.0,
          'avgPlayers': 0.0,
          'avgCompletion': 0.0,
          'dynamicDifficulty': 0, // 0 = no data yet
          'isLoading': false,
        };
      }

      final successCount = completed.where((r) => r.isSuccess).length;
      final failCount = completed.length - successCount;
      final successRate = successCount / completed.length;

      // Average time
      final totalMinutes = completed.fold<int>(0, (s, r) => s + r.timePlayedMinutes);
      final avgMinutes = (totalMinutes / completed.length).round();
      final avgTime =
          '${(avgMinutes ~/ 60).toString().padLeft(2, '0')}:${(avgMinutes % 60).toString().padLeft(2, '0')}';

      // Average clues used per session
      final avgClues = completed.fold<int>(0, (s, r) => s + r.cluesUsed) / completed.length;

      // Average players per session
      final avgPlayers = completed.fold<int>(0, (s, r) => s + r.playerCount) / completed.length;

      // Average completion percentage
      final avgCompletion =
          completed.fold<int>(0, (s, r) => s + r.percentageCompleted) / completed.length;

      // --- Dynamic difficulty score (1–5) ---
      // Based on: low success rate → harder | many clues used → harder
      // Formula: difficulty = round(5 - (successRate * 3) + (avgClues / 3))
      // Clamped to [1, 5]. With 0 data it stays 0 (no stars).
      final rawDifficulty = 5 - (successRate * 3) + (avgClues / 3);
      final dynamicDifficulty = rawDifficulty.round().clamp(1, 5);

      return {
        'successRate': successRate,
        'avgTime': avgTime,
        'totalGames': completed.length,
        'successCount': successCount,
        'failCount': failCount,
        'avgClues': avgClues,
        'avgPlayers': avgPlayers,
        'avgCompletion': avgCompletion,
        'dynamicDifficulty': dynamicDifficulty,
        'isLoading': false,
      };
    },
    loading: () => {
      'successRate': 0.0,
      'avgTime': '--:--',
      'totalGames': 0,
      'successCount': 0,
      'failCount': 0,
      'avgClues': 0.0,
      'avgPlayers': 0.0,
      'avgCompletion': 0.0,
      'dynamicDifficulty': 0,
      'isLoading': true,
    },
    error: (_, __) => {
      'successRate': 0.0,
      'avgTime': '--:--',
      'totalGames': 0,
      'successCount': 0,
      'failCount': 0,
      'avgClues': 0.0,
      'avgPlayers': 0.0,
      'avgCompletion': 0.0,
      'dynamicDifficulty': 0,
      'isError': true,
    },
  );
});
