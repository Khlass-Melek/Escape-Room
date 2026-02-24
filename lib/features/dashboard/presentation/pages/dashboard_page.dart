
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/dashboard/data/game_session_provider.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:gap/gap.dart';

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
  String? _selectedCameraId;

  String get _scenarioName {
    final asyncScenarios = ref.watch(scenarioProvider);
    return asyncScenarios.value?.firstWhere((s) => s.id == widget.scenarioId).name ?? "CHARGEMENT...";
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final asyncScenarios = ref.watch(scenarioProvider);
    final session = ref.watch(gameSessionProvider);
    final sessionNotifier = ref.read(gameSessionProvider.notifier);

    final bool isRunning = session.isRunning && session.scenarioId == widget.scenarioId;

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
                        ? 'FOCUS : $_selectedCameraId'
                        : _scenarioName.toUpperCase(),
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
              _StatusBadge(isRunning: isRunning),
            ],
            const Gap(16),
            _DigitalTimer(remaining: isRunning ? session.remaining : kSessionDuration, isSmall: isMobile),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
            child: isRunning
                ? _ActionButton(
                    label: 'ARRÊTER',
                    icon: Icons.stop_rounded,
                    color: AppTheme.secondaryRed,
                    isSmall: isMobile,
                    onPressed: () {
                      _showResetDialog(context, sessionNotifier);
                    },
                  )
                : _ActionButton(
                    label: 'DÉMARRER',
                    icon: Icons.play_arrow_rounded,
                    color: AppTheme.successGreen,
                    isSmall: isMobile,
                    onPressed: () {
                      sessionNotifier.startSession(widget.scenarioId);
                      // Refresh scenario list to show updated status
                      ref.invalidate(scenarioProvider);
                    },
                  ),
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
                scenarioId: widget.scenarioId,
                cameraId: _selectedCameraId!,
                isMobile: isMobile,
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: isMobile
                    ? Column(
                        children: [
                          if (isMobile) ...[
                            _StatusBadge(isRunning: isRunning),
                            const Gap(24),
                          ],
                          asyncScenarios.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, s) => Center(child: Text('Erreur: $e')),
                            data: (scenarios) {
                              final scenario = scenarios.firstWhere((s) => s.id == widget.scenarioId);
                              return CameraGridWidget(
                                cameras: scenario.cameras,
                                scenarioId: widget.scenarioId,
                                onCameraSelected: (id) => setState(() => _selectedCameraId = id),
                              );
                            },
                          ),
                          const Gap(24),
                          MusicControlWidget(scenarioId: widget.scenarioId),
                          const Gap(20),
                          HintControlWidget(scenarioId: widget.scenarioId),
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
                            child: asyncScenarios.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, s) => Center(child: Text('Erreur: $e')),
                              data: (scenarios) {
                                final scenario = scenarios.firstWhere((s) => s.id == widget.scenarioId);
                                return CameraGridWidget(
                                  cameras: scenario.cameras,
                                  scenarioId: widget.scenarioId,
                                  onCameraSelected: (id) => setState(() => _selectedCameraId = id),
                                );
                              },
                            ),
                          ),
                          const Gap(24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                MusicControlWidget(scenarioId: widget.scenarioId),
                                const Gap(20),
                                HintControlWidget(scenarioId: widget.scenarioId),
                                const Gap(20),
                                const LightingControlWidget(),
                                const Gap(40),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, GameSessionNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('RÉINITIALISER LA SESSION', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
        content: const Text(
          'Voulez-vous arrêter et réinitialiser le scénario ? Le minuteur sera remis à 60:00.',
          style: TextStyle(color: AppTheme.grayText, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text('ANNULER', style: TextStyle(color: AppTheme.grayText)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('RÉINITIALISER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              notifier.resetSession();
              ref.invalidate(scenarioProvider);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isRunning;
  const _StatusBadge({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isRunning ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRunning ? AppTheme.primaryRed : AppTheme.successGreen,
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
              color: isRunning ? AppTheme.primaryRed : AppTheme.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? AppTheme.primaryRed : AppTheme.successGreen).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const Gap(8),
          Text(
            isRunning ? 'SESSION EN COURS' : 'PRÊT POUR LANCEMENT',
            style: TextStyle(
              color: isRunning ? AppTheme.primaryRed : AppTheme.successGreen,
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
  final Duration remaining;
  final bool isSmall;
  const _DigitalTimer({required this.remaining, this.isSmall = false});

  String _format(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0 ? "$h:$m:$s" : "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isLow = remaining.inMinutes < 10;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLow ? AppTheme.primaryRed : AppTheme.grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(isLow ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _format(remaining),
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmall;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: isSmall ? 18 : 20),
              if (!isSmall) ...[
                const Gap(8),
                Text(
                  label,
                  style: const TextStyle(
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