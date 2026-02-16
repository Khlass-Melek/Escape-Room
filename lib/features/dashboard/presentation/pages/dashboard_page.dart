
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

// Placeholder Widgets - will be moved to separate files later
import 'package:escape_room_admin/features/dashboard/presentation/widgets/camera_grid_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/music_control_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/hint_control_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/lighting_control_widget.dart';

import 'package:escape_room_admin/features/dashboard/presentation/widgets/room_focus_view.dart';
import 'package:escape_room_admin/shared/utils/responsive.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final String scenarioId;

  const DashboardPage({super.key, required this.scenarioId});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Mock State
  bool _isPlaying = false;
  Duration _elapsed = const Duration(minutes: 25, seconds: 34);
  String? _selectedCameraId;

  // In a real app, these would come from a provider based on scenarioId
  final String scenarioName = "SAW I"; 

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryBlack,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            if (_selectedCameraId != null)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() => _selectedCameraId = null),
                tooltip: 'Retour à la grille',
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCameraId != null 
                        ? 'FOCUS : ${_selectedCameraId}'
                        : scenarioName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: isMobile ? 14 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${widget.scenarioId}',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const Gap(24),
              _StatusBadge(isPlaying: _isPlaying),
            ],
            const Gap(16),
            _DigitalTimer(duration: _elapsed, isSmall: isMobile),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
            child: _StopButton(onPressed: () {}, isSmall: isMobile),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppTheme.secondaryBlack.withOpacity(0.5),
              AppTheme.primaryBlack,
            ],
          ),
        ),
        child: _selectedCameraId != null 
            ? RoomFocusView(
                cameraId: _selectedCameraId!,
                isMobile: isMobile,
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: isMobile 
                  ? Column(
                      children: [
                        if (isMobile) ...[
                          _StatusBadge(isPlaying: _isPlaying),
                          const Gap(24),
                        ],
                        CameraGridWidget(
                          onCameraSelected: (id) => setState(() => _selectedCameraId = id),
                        ),
                        const Gap(24),
                        const MusicControlWidget(),
                        const Gap(20),
                        const HintControlWidget(),
                        const Gap(20),
                        const LightingControlWidget(),
                        const Gap(40),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CameraGridWidget(
                            onCameraSelected: (id) => setState(() => _selectedCameraId = id),
                          ),
                        ),
                        const Gap(24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: const [
                              MusicControlWidget(),
                              Gap(20),
                              HintControlWidget(),
                              Gap(20),
                              LightingControlWidget(),
                              Gap(40),
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPlaying;
  const _StatusBadge({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPlaying ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPlaying ? AppTheme.primaryRed : AppTheme.successGreen,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isPlaying ? AppTheme.primaryRed : AppTheme.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isPlaying ? AppTheme.primaryRed : AppTheme.successGreen).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const Gap(8),
          Text(
            isPlaying ? 'SESSION EN COURS' : 'PRÊT POUR LANCEMENT',
            style: TextStyle(
              color: isPlaying ? AppTheme.primaryRed : AppTheme.successGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalTimer extends StatelessWidget {
  final Duration duration;
  final bool isSmall;
  const _DigitalTimer({required this.duration, this.isSmall = false});

  String _format(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String h = twoDigits(d.inHours);
    String m = twoDigits(d.inMinutes.remainder(60));
    String s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _format(duration),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: isSmall ? 18 : 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryRed,
          letterSpacing: isSmall ? 1 : 2,
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmall;
  const _StopButton({required this.onPressed, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryRed,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryRed.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stop_rounded, color: Colors.white, size: isSmall ? 18 : 20),
              if (!isSmall) ...[
                const Gap(8),
                const Text(
                  'ARRÊTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _ControlPlaceholder extends StatelessWidget {
  final String title;
  const _ControlPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(title, style: const TextStyle(color: AppTheme.grayText)),
      ),
    );
  }
}