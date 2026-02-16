
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MusicControlWidget extends StatefulWidget {
  const MusicControlWidget({super.key});

  @override
  State<MusicControlWidget> createState() => _MusicControlWidgetState();
}

class _MusicControlWidgetState extends State<MusicControlWidget> {
  // Mock State
  bool isPlaying = false;
  double volume = 0.7;
  double progress = 0.3;
  String currentTrack = "Main Theme - Suspense";
  String artist = "The Room OST";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryRed, size: 20),
              ),
              const Gap(12),
              const Text(
                'AUDIO SYSTÈME',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.playlist_play_rounded, color: AppTheme.grayText),
                onPressed: () {},
              ),
            ],
          ),
          const Gap(24),
          
          // Track Info & Progress
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.grayBorder, width: 0.5),
                ),
                child: const Icon(Icons.album_rounded, color: AppTheme.grayText, size: 30),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTrack,
                      style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      artist,
                      style: const TextStyle(color: AppTheme.grayText, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),

          // Progress Slider
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: progress,
                  activeColor: AppTheme.primaryRed,
                  inactiveColor: AppTheme.grayBorder,
                  onChanged: (v) => setState(() => progress = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('01:23', style: TextStyle(color: AppTheme.grayText, fontSize: 10)),
                    Text('04:15', style: TextStyle(color: AppTheme.grayText, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          
          const Gap(16),

          // Main Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.white),
                onPressed: () {},
              ),
              const Gap(12),
              GestureDetector(
                onTap: () => setState(() => isPlaying = !isPlaying),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryRed,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.white,
                    size: 32,
                  ),
                ),
              ),
              const Gap(12),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: AppTheme.white),
                onPressed: () {},
              ),
            ],
          ),

          const Gap(24),
          
          // Volume
          Row(
            children: [
              Icon(volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 18, color: AppTheme.grayText),
              const Gap(8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  ),
                  child: Slider(
                    value: volume,
                    activeColor: AppTheme.grayText,
                    inactiveColor: AppTheme.grayBorder,
                    onChanged: (v) => setState(() => volume = v),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
