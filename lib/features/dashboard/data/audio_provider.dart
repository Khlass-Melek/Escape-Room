import 'package:flutter/foundation.dart';
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

  /// Scans the bucket recursively and returns a map of {title: publicUrl} for all audio files found.
  Future<Map<String, String>> scanBucket({String bucketName = 'audio', String? folderPath}) async {
    final result = <String, String>{};
    final audioExtensions = ['.mp3', '.wav', '.ogg', '.aac', '.flac', '.m4a', '.wma', '.opus'];
    
    // Ensure path doesn't have leading/trailing slashes
    String cleanPath = (folderPath ?? '').trim();
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.endsWith('/')) cleanPath = cleanPath.substring(0, cleanPath.length - 1);

    Future<void> listPath(String p) async {
      debugPrint('[scanBucket] Listing folder: "$p" in bucket: $bucketName');
      try {
        final objects = await _supabase.storage.from(bucketName).list(path: p.isEmpty ? null : p);
        debugPrint('[scanBucket] Found ${objects.length} items in "$p"');
        
        for (final obj in objects) {
          final name = obj.name;
          if (name == null || name.isEmpty || name == '.emptyFolderPlaceholder') continue;
          
          final fullPath = p.isEmpty ? name : '$p/$name';
          
          // Check if it's an audio file
          final isAudio = audioExtensions.any((ext) => name.toLowerCase().endsWith(ext));
          
          if (isAudio) {
            final url = _supabase.storage.from(bucketName).getPublicUrl(fullPath);
            final title = name
                .replaceAll(RegExp(r'\.(mp3|wav|ogg|aac|flac|m4a|wma|opus)$', caseSensitive: false), '')
                .replaceAll('_', ' ').replaceAll('-', ' ');
            result[title] = url;
            debugPrint('[scanBucket] Added track: $title');
          } else if (!name.contains('.')) {
            // It's likely a folder — recurse
            await listPath(fullPath);
          }
        }
      } catch (e) {
        debugPrint('[scanBucket] Error listing "$p": $e');
        // If it's a permission error, we should ideally let the user know
        if (e.toString().contains('403') || e.toString().contains('permission')) {
          throw 'Permission refusée : vérifiez vos politiques (Policies) Supabase.';
        }
        rethrow;
      }
    }

    await listPath(cleanPath);
    return result;
  }

  /// Imports explicit tracks (title → url map) into the audio_tracks table.
  Future<int> importTracks(Map<String, String> tracks) async {
    if (_scenarioId == null || tracks.isEmpty) return 0;
    final inserts = tracks.entries.map((e) => {
      'scenario_id': _scenarioId,
      'title': e.key,
      'filename': e.value,
    }).toList();
    await _supabase.from('audio_tracks').insert(inserts);
    final refreshed = await _fetchData(_scenarioId!);
    state = AsyncValue.data(state.value!.copyWith(tracks: refreshed));
    return inserts.length;
  }

  /// Scans a Supabase Storage bucket folder and bulk-imports all audio files.
  /// Returns the number of tracks imported, or throws on error.
  Future<int> importFromBucket({String bucketName = 'audio', String? folderPath}) async {
    if (_scenarioId == null) return 0;

    try {
      // List all files in the bucket (or a specific folder)
      // Note: supabase list() requires a path without leading slash
      final path = (folderPath == null || folderPath.isEmpty) ? '' : folderPath;
      
      debugPrint('[importFromBucket] Listing bucket: $bucketName, path: "$path"');
      
      final fileObjects = await _supabase.storage
          .from(bucketName)
          .list(path: path);

      debugPrint('[importFromBucket] Found ${fileObjects.length} total objects: ${fileObjects.map((f) => f.name).toList()}');

      // Filter only audio files (check for null name & match extension)
      final audioExtensions = ['.mp3', '.wav', '.ogg', '.aac', '.flac', '.m4a', '.wma', '.opus'];
      final audioFiles = fileObjects.where((f) {
        if (f.name == null || f.name!.isEmpty) return false;
        // Skip folders (.emptyFolderPlaceholder and items without dots)
        final name = f.name!.toLowerCase();
        return audioExtensions.any((ext) => name.endsWith(ext));
      }).toList();

      debugPrint('[importFromBucket] Found ${audioFiles.length} audio files after filter');

      if (audioFiles.isEmpty) {
        // Check if maybe there are sub-folders
        final folderNames = fileObjects.where((f) => f.name != null && !f.name!.contains('.')).map((f) => f.name).toList();
        if (folderNames.isNotEmpty) {
          debugPrint('[importFromBucket] Found sub-folders: $folderNames — try specifying one as sous-dossier');
        }
        return 0;
      }

      // Get public URLs and build insert batch
      final inserts = <Map<String, dynamic>>[];
      for (final file in audioFiles) {
        // Build full path for the public URL
        final filePath = path.isEmpty ? file.name! : '$path/${file.name}';
        final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);

        // Derive a clean title from the filename (remove extension)
        final title = file.name!
            .replaceAll(RegExp(r'\.(mp3|wav|ogg|aac|flac|m4a|wma|opus)$', caseSensitive: false), '')
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');

        debugPrint('[importFromBucket] Adding: $title → $publicUrl');

        inserts.add({
          'scenario_id': _scenarioId,
          'title': title,
          'filename': publicUrl,
        });
      }

      // Batch insert all tracks
      await _supabase.from('audio_tracks').insert(inserts);

      // Refresh local state
      final tracks = await _fetchData(_scenarioId!);
      state = AsyncValue.data(state.value!.copyWith(tracks: tracks));

      return inserts.length;
    } catch (e, stack) {
      debugPrint('[importFromBucket] Error: $e\n$stack');
      rethrow;
    }
  }
}

final audioProvider = AsyncNotifierProvider<AudioNotifier, AudioState>(() {
  return AudioNotifier();
});
