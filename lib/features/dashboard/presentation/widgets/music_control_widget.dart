
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/dashboard/data/audio_provider.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicControlWidget extends ConsumerStatefulWidget {
  final String scenarioId;
  const MusicControlWidget({super.key, required this.scenarioId});

  @override
  ConsumerState<MusicControlWidget> createState() => _MusicControlWidgetState();
}

class _MusicControlWidgetState extends ConsumerState<MusicControlWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showPlaylist = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(audioProvider.notifier).loadTracks(widget.scenarioId));
    
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) {
      ref.read(audioProvider.notifier).nextTrack();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String? _lastPlayedUrl;

  void _handlePlayback(AudioState state) async {
    final currentTrack = state.currentTrack;
    
    if (state.isPlaying) {
      if (currentTrack != null) {
        final String newUrl = currentTrack.filename;
        
        // Only call play if the track has actually changed
        if (newUrl != _lastPlayedUrl) {
          _lastPlayedUrl = newUrl;
          if (newUrl.startsWith('http')) {
            await _audioPlayer.play(UrlSource(newUrl));
          } else {
            try {
              await _audioPlayer.play(AssetSource(newUrl));
            } catch (e) {
              debugPrint('Error playing asset: $e');
            }
          }
        } else if (_audioPlayer.state == PlayerState.paused) {
          // If it was paused but the track is the same, just resume
          await _audioPlayer.resume();
        }
      }
    } else {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
      }
    }
    
    // Always update volume without restarting playback
    await _audioPlayer.setVolume(state.volume);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioAsync = ref.watch(audioProvider);
    final scenariosAsync = ref.watch(scenarioProvider);
    
    // Synergize local player with provider state
    ref.listen(audioProvider, (previous, next) {
      if (next.hasValue) {
        _handlePlayback(next.value!);
      }
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: audioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.primaryRed))),
        data: (state) {
          final scenario = scenariosAsync.asData?.value.firstWhere((s) => s.id == widget.scenarioId);
          final currentTrack = state.currentTrack;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryRed, size: 20),
                  ),
                  const Gap(16),
                  const Text(
                    'AUDIO SYSTÈME',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showPlaylist ? Icons.close_rounded : Icons.playlist_play_rounded,
                      color: _showPlaylist ? AppTheme.primaryRed : AppTheme.grayText,
                    ),
                    onPressed: () => setState(() => _showPlaylist = !_showPlaylist),
                  ),
                ],
              ),
              const Gap(24),

              if (_showPlaylist) ...[
                // Playlist View
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    itemCount: state.tracks.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, index) {
                      final track = state.tracks[index];
                      final isCurrent = state.currentTrackIndex == index;
                      return ListTile(
                        onTap: () {
                          ref.read(audioProvider.notifier).setTrack(index);
                          setState(() => _showPlaylist = false);
                        },
                        dense: true,
                        leading: Icon(
                          isCurrent ? Icons.volume_up_rounded : Icons.play_circle_fill_rounded, 
                          color: isCurrent ? AppTheme.primaryRed : AppTheme.grayText, 
                          size: 20
                        ),
                        title: Text(
                          track.title.toUpperCase(), 
                          style: TextStyle(
                            color: isCurrent ? AppTheme.primaryRed : AppTheme.white, 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                        subtitle: Text(track.filename, style: const TextStyle(color: AppTheme.grayText, fontSize: 9)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: isCurrent ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.primaryBlack.withOpacity(0.3),
                      );
                    },
                  ),
                ),
              ] else ...[
                // Player View
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
                        image: currentTrack != null ? const DecorationImage(
                          image: AssetImage('assets/images/scenario_placeholder.jpg'),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        ) : null,
                      ),
                      child: const Icon(Icons.album_rounded, color: AppTheme.grayText, size: 32),
                    ),
                    const Gap(20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrack?.title.toUpperCase() ?? 'AUCUNE PISTE',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            scenario?.name.toUpperCase() ?? 'OST',
                            style: const TextStyle(color: AppTheme.grayText, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(32),
                
                // Progress
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppTheme.primaryRed,
                        inactiveTrackColor: AppTheme.grayBorder.withOpacity(0.3),
                        thumbColor: AppTheme.primaryRed,
                      ),
                      child: Slider(
                        value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0.0,
                        onChanged: (v) {
                          final newPos = Duration(seconds: (v * _duration.inSeconds).toInt());
                          _audioPlayer.seek(newPos);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position), style: const TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          Text(_formatDuration(_duration), style: const TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(24),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.white, size: 28),
                      onPressed: () => ref.read(audioProvider.notifier).prevTrack(),
                    ),
                    const Gap(24),
                    GestureDetector(
                      onTap: () => ref.read(audioProvider.notifier).togglePlay(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryRed,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppTheme.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const Gap(24),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: AppTheme.white, size: 28),
                      onPressed: () => ref.read(audioProvider.notifier).nextTrack(),
                    ),
                  ],
                ),
              ],

              const Gap(32),
              // Volume
              Row(
                children: [
                  Icon(
                    state.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: AppTheme.grayText,
                    size: 20,
                  ),
                  const Gap(12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: AppTheme.grayText,
                        inactiveTrackColor: AppTheme.grayBorder.withOpacity(0.2),
                        thumbColor: AppTheme.grayText,
                      ),
                      child: Slider(
                        value: state.volume,
                        onChanged: (v) => ref.read(audioProvider.notifier).setVolume(v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
