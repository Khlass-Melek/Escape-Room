import 'package:escape_room_admin/models/scenario.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class ScenarioNotifier extends AsyncNotifier<List<Scenario>> {
  final _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Scenario>> build() async {
    return _fetchData();
  }

  Future<List<Scenario>> _fetchData() async {
    final resp = await _supabase.from('scenarios').select().order('created_at');
    
    // If empty initially (after purely running the script without inserting rows), insert a default one to preserve the UI Look and Feel
    if (resp.isEmpty) {
      await _supabase.from('scenarios').insert([
        {'name': 'SAW I', 'description': 'Jeu de survie', 'is_active': true, 'estimated_time': 60, 'difficulty': 4},
        {'name': 'SAW II', 'description': 'Suite du jeu', 'is_active': false, 'estimated_time': 75, 'difficulty': 5},
        {'name': 'PIRATES DES CARAÏBES', 'description': 'Chasse au trésor', 'is_active': false, 'estimated_time': 60, 'difficulty': 3},
      ]);
      final newResp = await _supabase.from('scenarios').select().order('created_at');
      return newResp.map((row) => Scenario.fromJson(row)).toList();
    }

    return resp.map((row) => Scenario.fromJson(row)).toList();
  }

  Future<void> addScenario(Map<String, dynamic> scenarioData, Map<String, String?> enigmaCameraMappings) async {
    state = const AsyncValue.loading();
    try {
      final inserted = await _supabase.from('scenarios').insert(scenarioData).select().single();
      final newScenarioId = inserted['id'];

      // Assign enigmas with camera IPs
      if (enigmaCameraMappings.isNotEmpty) {
        final mappings = enigmaCameraMappings.entries.map((entry) => {
          'scenario_id': newScenarioId,
          'puzzle_id': entry.key,
          'camera_ip': entry.value,
        }).toList();
        await _supabase.from('scenario_puzzles').insert(mappings);
      }
      
      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateScenario(String id, Map<String, dynamic> scenarioData, Map<String, String?> enigmaCameraMappings) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('scenarios').update(scenarioData).eq('id', id);

      // Re-assign enigmas (delete old, insert new with camera IPs)
      await _supabase.from('scenario_puzzles').delete().eq('scenario_id', id);
      if (enigmaCameraMappings.isNotEmpty) {
        final mappings = enigmaCameraMappings.entries.map((entry) => {
          'scenario_id': id,
          'puzzle_id': entry.key,
          'camera_ip': entry.value,
        }).toList();
        await _supabase.from('scenario_puzzles').insert(mappings);
      }

      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteScenario(String id) async {
    state = const AsyncValue.loading();
    try {
      // cascade should handle scenario_puzzles, but if not we can delete manually
      await _supabase.from('scenario_puzzles').delete().eq('scenario_id', id);
      await _supabase.from('scenarios').delete().eq('id', id);
      
      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final scenarioProvider = AsyncNotifierProvider<ScenarioNotifier, List<Scenario>>(() {
  return ScenarioNotifier();
});
