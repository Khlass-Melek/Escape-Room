
import 'dart:convert';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/dashboard/data/game_session_provider.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:escape_room_admin/features/admin/data/enigma_provider.dart';
import 'package:gap/gap.dart';

import 'package:escape_room_admin/features/dashboard/presentation/widgets/camera_grid_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/music_control_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/hint_control_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/lighting_control_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/room_focus_view.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/game_report_form.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/cables_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/switches_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/plant_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/weight_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/sound_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/voice_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/tictactoe_enigma_widget.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/camera_viewer_widget.dart';
import 'package:escape_room_admin/core/services/mqtt_service.dart';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
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

    // Listen for session end to show report form
    ref.listen(gameSessionProvider, (previous, next) {
      if (next.needsReport && next.lastScenarioId == widget.scenarioId) {
        _showReportForm(context, next.lastScenarioId!);
      }
    });

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
                      
                      // -- CONFIGURER LES CÂBLES DYNAMIQUEMENT --
                      final enigmasState = ref.read(enigmaProvider).value;
                      if (enigmasState != null) {
                        try {
                          // === CÂBLAGE ===
                          final cablesEnigma = enigmasState.enigmas.where((e) => e.type == 'Câblage').firstOrNull;
                          if (cablesEnigma != null && cablesEnigma.configuration.containsKey('connections')) {
                            final connections = cablesEnigma.configuration['connections'] as Map<String, dynamic>;
                            final Map<String, int> sourceMap = {'Source 1': 0, 'Source 2': 1, 'Source 3': 2, 'Source 4': 3};
                            final Map<String, int> destMap = {'A': 4, 'B': 5, 'C': 6, 'D': 7};
                            List<List<int>> pairs = [];
                            for (var entry in connections.entries) {
                               final src = sourceMap[entry.key];
                               final dst = destMap[entry.value.toString()];
                               if (src != null && dst != null) pairs.add([src, dst]);
                            }
                            MqttService().publish('escape/room1/enigma/cables/command', jsonEncode({'action': 'config', 'pairs': pairs}));
                          } else {
                            MqttService().publish('escape/room1/enigma/cables/command', '{"action":"reset"}');
                          }

                          // === INTERRUPTEURS BINAIRES ===
                          final switchesEnigma = enigmasState.enigmas.where((e) => e.type == 'Interrupteurs Binaires').firstOrNull;
                          if (switchesEnigma != null && switchesEnigma.configuration.containsKey('switches')) {
                            final switches = (switchesEnigma.configuration['switches'] as List<dynamic>)
                                .map((e) => (e as int?) ?? 0).toList();
                            MqttService().publish('escape/room1/enigma/switches/command', jsonEncode({'action': 'config', 'target': switches}));
                          } else {
                            MqttService().publish('escape/room1/enigma/switches/command', '{"action":"reset"}');
                          }
                          // === PLANTE ===
                          final plantEnigma = enigmasState.enigmas.where((e) => e.type == 'Plante Eau').firstOrNull;
                          if (plantEnigma != null && plantEnigma.configuration.containsKey('water_threshold')) {
                            final threshold = plantEnigma.configuration['water_threshold'] as int? ?? 50;
                            MqttService().publish('escape/room1/enigma/plant/command', jsonEncode({'action': 'config', 'threshold': threshold}));
                          } else {
                            MqttService().publish('escape/room1/enigma/plant/command', '{"action":"reset"}');
                          }
                          // === POIDS ===
                          final weightEnigma = enigmasState.enigmas.where((e) => e.type == 'Capteurs de Poids').firstOrNull;
                          if (weightEnigma != null && weightEnigma.configuration.containsKey('target_weight_grams')) {
                            final targetG = weightEnigma.configuration['target_weight_grams'] as int? ?? 1000;
                            MqttService().publish('escape/room1/enigma/weight/command', jsonEncode({'action': 'config', 'target_g': targetG, 'margin_g': 20}));
                          } else {
                            MqttService().publish('escape/room1/enigma/weight/command', '{"action":"reset"}');
                          }
                          // === SON ===
                          final soundEnigma = enigmasState.enigmas.where((e) => e.type == 'Capteur Sonore').firstOrNull;
                          if (soundEnigma != null && soundEnigma.configuration.containsKey('t1')) {
                            final t1 = soundEnigma.configuration['t1'] as int? ?? 300;
                            final t2 = soundEnigma.configuration['t2'] as int? ?? 1000;
                            MqttService().publish('escape/room1/enigma/calm/command', jsonEncode({'action': 'config', 't1': t1, 't2': t2}));
                          } else {
                            MqttService().publish('escape/room1/enigma/calm/command', '{"action":"reset"}');
                          }
                          // === VOIX ===
                          final voiceEnigma = enigmasState.enigmas.where((e) => e.type == 'Reconnaissance Vocale').firstOrNull;
                          if (voiceEnigma != null && voiceEnigma.configuration.containsKey('target_phrase') && (voiceEnigma.configuration['target_phrase'] as String).trim().isNotEmpty) {
                            final phrase = voiceEnigma.configuration['target_phrase'] as String;
                            PublicMqttService().publish('rpi/challenge', phrase.split(',').first.trim());
                          } else {
                            PublicMqttService().publish('rpi/challenge', 'open the door now');
                          }
                        } catch (e) {
                          print('MQTT Erreur Config: $e');
                        }
                      } else {
                        MqttService().publish('escape/room1/enigma/cables/command', '{"action":"reset"}');
                        MqttService().publish('escape/room1/enigma/switches/command', '{"action":"reset"}');
                      }

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
                          const Gap(20),
                          const CablesEnigmaWidget(),
                          const Gap(20),
                          const SwitchesEnigmaWidget(),
                          const Gap(20),
                          const PlantEnigmaWidget(),
                          const Gap(20),
                          const WeightEnigmaWidget(),
                          const Gap(20),
                          const SoundEnigmaWidget(),
                          const Gap(20),
                          const VoiceEnigmaWidget(),
                          const Gap(20),
                          const TicTacToeEnigmaWidget(),
                          const Gap(20),
                          const CameraViewerWidget(),
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
                                const Gap(20),
                                const CablesEnigmaWidget(),
                                const Gap(20),
                                const SwitchesEnigmaWidget(),
                                const Gap(20),
                                const PlantEnigmaWidget(),
                                const Gap(20),
                                const WeightEnigmaWidget(),
                                const Gap(20),
                                const SoundEnigmaWidget(),
                                const Gap(20),
                                const VoiceEnigmaWidget(),
                                const Gap(20),
                                const TicTacToeEnigmaWidget(),
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

  void _showReportForm(BuildContext context, String scenarioId) async {
    // Clear the flag immediately to prevent re-triggering
    ref.read(gameSessionProvider.notifier).markReportAsHandled();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameReportForm(scenarioId: scenarioId),
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
              Navigator.of(ctx).pop();
              // Envoyer l'ordre de réinitialiser toutes les énigmes
              try {
                MqttService().publish('escape/room1/enigma/cables/command', '{"action":"reset"}');
                PublicMqttService().publish('rpi/challenge', '');
                PublicMqttService().publish('escape/room1/enigma/tictactoe/command', '{"action":"reset"}');
              } catch (e) {
                print("MQTT Erreur: $e");
              }
              // Add a tiny delay to allow the dialog animation to start closing
              Future.delayed(const Duration(milliseconds: 100), () {
                notifier.resetSession();
                ref.invalidate(scenarioProvider);
              });
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

