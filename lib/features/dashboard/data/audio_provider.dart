import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class AudioTrack {
  final String id;
  final String title;
  final String filename;
  final String scenarioId;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.filename,
    required this.scenarioId,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? 'Sans titre',
      filename: json['filename']?.toString() ?? '',
      scenarioId: json['scenario_id']?.toString() ?? '',
    );
  }
}

class AudioState {
  final List<AudioTrack> tracks;
  final int currentTrackIndex;
  final bool isPlaying;
  final double volume;
  final double progress;

  const AudioState({
    required this.tracks,
    this.currentTrackIndex = 0,
    this.isPlaying = false,
    this.volume = 0.7,
    this.progress = 0.0,
  });

  bool get hasTracks => tracks.isNotEmpty;
  AudioTrack? get currentTrack => hasTracks ? tracks[currentTrackIndex] : null;

  AudioState copyWith({
    List<AudioTrack>? tracks,
    int? currentTrackIndex,
    bool? isPlaying,
    double? volume,
    double? progress,
  }) {
    return AudioState(
      tracks: tracks ?? this.tracks,
      currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      progress: progress ?? this.progress,
    );
  }
}

class AudioNotifier extends AsyncNotifier<AudioState> {
  final _supabase = supa.Supabase.instance.client;
  String? _scenarioId;

  @override
  Future<AudioState> build() async {
    return const AudioState(tracks: []);
  }

  Future<void> loadTracks(String scenarioId) async {
    if (_scenarioId == scenarioId && state.hasValue) return;
    _scenarioId = scenarioId;
    state = const AsyncValue.loading();
    try {
      final tracks = await _fetchData(scenarioId);
      state = AsyncValue.data(AudioState(tracks: tracks));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<AudioTrack>> _fetchData(String scenarioId) async {
    final resp = await _supabase
        .from('audio_tracks')
        .select()
        .eq('scenario_id', scenarioId)
        .order('title');

    return resp.map((row) => AudioTrack.fromJson(row)).toList();
  }

  void togglePlay() {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(isPlaying: !state.value!.isPlaying));
  }

  void setTrack(int index) {
    if (!state.hasValue) return;
    if (index >= 0 && index < state.value!.tracks.length) {
      state = AsyncValue.data(state.value!.copyWith(currentTrackIndex: index, progress: 0.0, isPlaying: true));
    }
  }

  void nextTrack() {
    if (!state.hasValue || !state.value!.hasTracks) return;
    final next = (state.value!.currentTrackIndex + 1) % state.value!.tracks.length;
    setTrack(next);
  }

  void prevTrack() {
    if (!state.hasValue || !state.value!.hasTracks) return;
    final prev = (state.value!.currentTrackIndex - 1 + state.value!.tracks.length) % state.value!.tracks.length;
    setTrack(prev);
  }

  void setVolume(double volume) {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(volume: volume));
  }

  void setProgress(double progress) {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(progress: progress));
  }

  Future<void> addTrack(String title, String filename) async {
    if (!state.hasValue || _scenarioId == null) return;
    try {
      await _supabase.from('audio_tracks').insert({
        'scenario_id': _scenarioId,
        'title': title,
        'filename': filename,
      });
      final tracks = await _fetchData(_scenarioId!);
      state = AsyncValue.data(state.value!.copyWith(tracks: tracks));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTrack(String id) async {
    if (!state.hasValue || _scenarioId == null) return;
    try {
      await _supabase.from('audio_tracks').delete().eq('id', id);
      final tracks = await _fetchData(_scenarioId!);
      state = AsyncValue.data(state.value!.copyWith(tracks: tracks));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final audioProvider = AsyncNotifierProvider<AudioNotifier, AudioState>(() {
  return AudioNotifier();
});
