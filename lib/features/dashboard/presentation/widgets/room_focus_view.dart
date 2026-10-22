import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_room_admin/features/admin/data/enigma_provider.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'tic_tac_toe_control_widget.dart';

class RoomFocusView extends StatefulWidget {
  final String scenarioId;
  final String cameraId;
  final bool isMobile;

  const RoomFocusView({
    super.key,
    required this.scenarioId,
    required this.cameraId,
    required this.isMobile,
  });

  @override
  State<RoomFocusView> createState() => _RoomFocusViewState();
}

class _RoomFocusViewState extends State<RoomFocusView> {
  Map<String, dynamic>? _linkedEnigma;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinkedEnigma();
  }

  Future<void> _fetchLinkedEnigma() async {
    final client = supa.Supabase.instance.client;
    try {
      debugPrint('[RoomFocusView] Fetching enigma for scenario=${widget.scenarioId} camera=${widget.cameraId}');
      
      // First: try to find an enigma linked to this exact camera IP
      final res = await client
          .from('scenario_puzzles')
          .select('*, puzzles(*)')
          .eq('scenario_id', widget.scenarioId)
          .eq('camera_ip', widget.cameraId);
      
      debugPrint('[RoomFocusView] camera_ip query returned ${res.length ?? 0} rows: $res');
      
      if (res.isNotEmpty) {
        final firstMatch = res.first;
        if (firstMatch['puzzles'] != null) {
          setState(() {
            _linkedEnigma = firstMatch['puzzles'];
            _isLoading = false;
          });
          return;
        }
      }

      // Fallback: if camera_ip column doesn't exist yet or no result, 
      // try getting any puzzle linked to this scenario
      debugPrint('[RoomFocusView] Falling back to scenario-only query');
      final fallbackRes = await client
          .from('scenario_puzzles')
          .select('*, puzzles(*)')
          .eq('scenario_id', widget.scenarioId);
      
      debugPrint('[RoomFocusView] fallback query returned ${fallbackRes.length ?? 0} rows: $fallbackRes');

      if (fallbackRes.isNotEmpty) {
        final firstMatch = fallbackRes.first;
        if (firstMatch['puzzles'] != null) {
          setState(() {
            _linkedEnigma = firstMatch['puzzles'];
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[RoomFocusView] Error fetching linked enigma: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _LargeCameraFeed(cameraId: widget.cameraId),
            const Gap(24),
            if (_linkedEnigma != null) ...[
              _EnigmaActuators(enigma: _linkedEnigma!),
              const Gap(24),
              if (_linkedEnigma!['type'] == 'Tic Tac Toe')
                TicTacToeControlWidget(
                  enigmaName: _linkedEnigma!['name'] ?? 'Tic Tac Toe',
                  aiDifficulty: _linkedEnigma!['config']?['ia_difficulty'] ?? 'Moyen',
///     raspberryPiIp: '192.168.1.42',
                  raspberryPiIp: widget.cameraId,
                ),
              const Gap(24),
              _ConfigurationTerminal(enigma: _linkedEnigma!),
            ] else 
              _NoEnigmaPlaceholder(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Camera
          Expanded(
            flex: 3,
            child: _LargeCameraFeed(cameraId: widget.cameraId),
          ),
          const Gap(24),
          // Right: Controls & Config
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_linkedEnigma != null) ...[
                    _EnigmaActuators(enigma: _linkedEnigma!),
                    const Gap(24),
                    if (_linkedEnigma!['type'] == 'Tic Tac Toe')
                      TicTacToeControlWidget(
                        enigmaName: _linkedEnigma!['name'] ?? 'Tic Tac Toe',
                        aiDifficulty: _linkedEnigma!['config']?['ia_difficulty'] ?? 'Moyen',
                        raspberryPiIp: widget.cameraId,
                      ),
                    const Gap(24),
                    _ConfigurationTerminal(enigma: _linkedEnigma!),
                  ] else 
                    _NoEnigmaPlaceholder(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEnigmaPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.grayBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.extension_off_rounded, color: AppTheme.grayText.withValues(alpha: 0.5), size: 48),
          const Gap(16),
          const Text(
            "IL N'Y A PAS D'ÉNIGME DANS CETTE CHAMBRE",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.grayText, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


class _LargeCameraFeed extends StatelessWidget {
  final String cameraId;
  const _LargeCameraFeed({required this.cameraId});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Mock Video
              Image.network(
                'https://media.giphy.com/media/oEI9uWUqW8K6A/giphy.gif',
                fit: BoxFit.cover,
              ),
              
              // Overlays
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),

              // Tech indicators
              const Positioned(
                top: 20,
                left: 20,
                child: _TechTag(label: 'STREAM: ACTIVE', color: AppTheme.successGreen),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: _TechTag(label: 'RES: 1080P', color: AppTheme.white.withValues(alpha: 0.5)),
              ),

              // Center Crosshair
              const Center(
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(Icons.add_rounded, color: AppTheme.white, size: 40),
                ),
              ),

              // Bottom Info
              Positioned(
                bottom: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cameraId,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'LOCATION: SECTEUR_ALPHA_01',
                      style: TextStyle(
                        color: AppTheme.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _TechTag extends StatelessWidget {
  final String label;
  final Color color;
  const _TechTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}

class _EnigmaActuators extends StatelessWidget {
  final Map<String, dynamic> enigma;
  const _EnigmaActuators({required this.enigma});

  @override
  Widget build(BuildContext context) {
    final String type = enigma['type']?.toString().toUpperCase() ?? 'INCONNU';
    final String name = enigma['name']?.toString().toUpperCase() ?? 'ÉNIGME';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppTheme.warningOrange, size: 20),
              const Gap(12),
              Expanded(
                child: Text(
                  'ACTIONNEURS : $name',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'MODULE : $type',
            style: const TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const Gap(24),
          _ActuatorButton(
            label: 'DÉVERROUILLER SYSTÈME',
            icon: Icons.lock_open_rounded,
            color: AppTheme.primaryRed,
            onPressed: () {},
          ),
          const Gap(12),
          _ActuatorButton(
            label: 'RÉINITIALISER MODULE',
            icon: Icons.refresh_rounded,
            color: AppTheme.successGreen,
            onPressed: () {},
          ),
          // We could add type-specific actuators here
        ],
      ),
    );
  }
}

class _ActuatorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActuatorButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: color.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(12),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigurationTerminal extends StatefulWidget {
  final Map<String, dynamic> enigma;
  const _ConfigurationTerminal({required this.enigma});

  @override
  State<_ConfigurationTerminal> createState() => _ConfigurationTerminalState();
}

class _ConfigurationTerminalState extends State<_ConfigurationTerminal> {
  late Map<String, dynamic> _config;

  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.enigma['config'] ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_input_component_rounded, color: AppTheme.primaryRed, size: 20),
              Gap(12),
              Text(
                'CONFIGURATION VARIABLES',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(24),
          if (_config.isEmpty)
            const Text(
              "AUCUNE VARIABLE DE CONFIGURATION POUR CE MODULE",
              style: TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold),
            )
          else
            ..._config.entries.map((entry) {
              if (entry.value is num) {
                final rawVal = (entry.value as num).toDouble();
                // Dynamically set max to at least the value's magnitude so slider never crashes
                final dynamicMax = rawVal > 100 ? (rawVal * 1.5).ceilToDouble() : 100.0;
                final clampedVal = rawVal.clamp(0.0, dynamicMax).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _ConfigSlider(
                    label: entry.key.toUpperCase(),
                    value: clampedVal,
                    min: 0,
                    max: dynamicMax,
                    onChanged: (val) => setState(() => _config[entry.key] = val),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _ConfigInput(
                    label: entry.key.toUpperCase(),
                    value: entry.value.toString(),
                    onChanged: (val) => setState(() => _config[entry.key] = val),
                  ),
                );
              }
            }),
          const Gap(8),
          Consumer(
            builder: (context, ref, _) => PrimaryButton(
              label: 'APPLIQUER MODIFICATIONS',
              icon: Icons.save_rounded,
              onPressed: () async {
                final id = widget.enigma['id']?.toString();
                if (id == null) return;
                
                // Fetch current enigma from provider to get other fields
                final enigmaState = ref.read(enigmaProvider);
                final enigmaModel = enigmaState.asData?.value.enigmas.firstWhere((e) => e.id == id);
                
                if (enigmaModel != null) {
                  await ref.read(enigmaProvider.notifier).updateEnigma(
                    id,
                    enigmaModel.name,
                    enigmaModel.type,
                    enigmaModel.description,
                    enigmaModel.difficulty,
                    enigmaModel.isActive,
                    _config, // New config
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('CONFIGURATION MISE À JOUR !'),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _ConfigSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ConfigSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              value.round().toString(),
              style: const TextStyle(color: AppTheme.primaryRed, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppTheme.primaryRed,
          inactiveColor: AppTheme.grayBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ConfigInput extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _ConfigInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const Gap(12),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          onChanged: onChanged,
          style: const TextStyle(color: AppTheme.white, fontSize: 14, fontFamily: 'monospace'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.grayBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
