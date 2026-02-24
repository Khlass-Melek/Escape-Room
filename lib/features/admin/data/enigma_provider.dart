import 'package:escape_room_admin/features/admin/domain/models/enigma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class EnigmaState {
  final List<Enigma> enigmas;

  const EnigmaState({
    this.enigmas = const [],
  });

  EnigmaState copyWith({
    List<Enigma>? enigmas,
  }) {
    return EnigmaState(
      enigmas: enigmas ?? this.enigmas,
    );
  }
}

class EnigmaNotifier extends AsyncNotifier<EnigmaState> {
  final _supabase = supa.Supabase.instance.client;

  @override
  Future<EnigmaState> build() async {
    return _fetchData();
  }

  Future<EnigmaState> _fetchData() async {
    // We map 'puzzles' to the Enigma concept
    final resp = await _supabase.from('puzzles').select().order('name');
    final enigmas = resp.map((row) {
      return Enigma(
        id: row['id'].toString(),
        name: row['name']?.toString() ?? 'Sans Nom',
        type: row['type']?.toString() ?? 'Inconnu',
        description: row['description']?.toString() ?? '',
        difficulty: row['difficulty']?.toString() ?? 'Moyen',
        isActive: row['is_active'] ?? true,
        configuration: Map<String, dynamic>.from(row['config'] ?? {}),
      );
    }).toList();

    return EnigmaState(enigmas: enigmas);
  }

  Future<void> addEnigma(String name, String type, String description, String difficulty, bool isActive, Map<String, dynamic> configuration) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('puzzles').insert({
        'name': name,
        'type': type,
        'description': description,
        'difficulty': difficulty,
        'is_active': isActive,
        'config': configuration,
      });

      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateEnigma(String id, String name, String type, String description, String difficulty, bool isActive, Map<String, dynamic> configuration) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('puzzles').update({
        'name': name,
        'type': type,
        'description': description,
        'difficulty': difficulty,
        'is_active': isActive,
        'config': configuration,
      }).eq('id', id);

      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> toggleEnigmaStatus(String id) async {
    if (!state.hasValue) return;
    
    final currentEnigmas = state.value!.enigmas;
    final enigmaIndex = currentEnigmas.indexWhere((e) => e.id == id);
    if (enigmaIndex == -1) return;
    
    final newStatus = !currentEnigmas[enigmaIndex].isActive;
    
    // Optimistic UI update could be done here, but let's let Supabase decide
    state = const AsyncValue.loading();
    try {
      await _supabase.from('puzzles').update({'is_active': newStatus}).eq('id', id);
      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteEnigma(String id) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('puzzles').delete().eq('id', id);
      state = AsyncValue.data(await _fetchData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final enigmaProvider = AsyncNotifierProvider<EnigmaNotifier, EnigmaState>(() {
  return EnigmaNotifier();
});
