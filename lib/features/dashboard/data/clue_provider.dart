import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class Clue {
  final String id;
  final String content;
  final String scenarioId;

  const Clue({
    required this.id,
    required this.content,
    required this.scenarioId,
  });

  factory Clue.fromJson(Map<String, dynamic> json) {
    return Clue(
      id: json['id'].toString(),
      content: json['content']?.toString() ?? '',
      scenarioId: json['scenario_id']?.toString() ?? '',
    );
  }
}

class ClueNotifier extends AsyncNotifier<List<Clue>> {
  final _supabase = supa.Supabase.instance.client;
  late String _scenarioId;

  @override
  Future<List<Clue>> build() async {
    // We will initialize _scenarioId via a helper or by passing it to the provider
    // However, AsyncNotifier.build doesn't take args in the base class.
    return [];
  }

  Future<void> loadClues(String scenarioId) async {
    _scenarioId = scenarioId;
    state = const AsyncValue.loading();
    try {
      final data = await _fetchData(scenarioId);
      state = AsyncValue.data(data);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<Clue>> _fetchData(String scenarioId) async {
    final resp = await _supabase
        .from('messages')
        .select()
        .eq('scenario_id', scenarioId)
        .order('created_at');

    return resp.map((row) => Clue.fromJson(row)).toList();
  }

  Future<void> addClue(String content) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('messages').insert({
        'scenario_id': _scenarioId,
        'content': content,
      });
      state = AsyncValue.data(await _fetchData(_scenarioId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteClue(String id) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('messages').delete().eq('id', id);
      state = AsyncValue.data(await _fetchData(_scenarioId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final clueProvider = AsyncNotifierProvider<ClueNotifier, List<Clue>>(() {
  return ClueNotifier();
});
