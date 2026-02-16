
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RoomFocusView extends StatelessWidget {
  final String cameraId;
  final bool isMobile;

  const RoomFocusView({
    super.key,
    required this.cameraId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _LargeCameraFeed(cameraId: cameraId),
            const Gap(24),
            _EnigmaActuators(),
            const Gap(24),
            _ConfigurationTerminal(),
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
            child: _LargeCameraFeed(cameraId: cameraId),
          ),
          const Gap(24),
          // Right: Controls & Config
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _EnigmaActuators(),
                  const Gap(24),
                  _ConfigurationTerminal(),
                ],
              ),
            ),
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
          border: Border.all(color: AppTheme.primaryRed.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.1),
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
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // Tech indicators
              Positioned(
                top: 20,
                left: 20,
                child: _TechTag(label: 'STREAM: ACTIVE', color: AppTheme.successGreen),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: _TechTag(label: 'RES: 1080P', color: AppTheme.white.withOpacity(0.5)),
              ),

              // Center Crosshair
              Center(
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
                        color: AppTheme.white.withOpacity(0.7),
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
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}

class _EnigmaActuators extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              const Text(
                'ACTIONNEURS SYSTÈME',
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
          _ActuatorButton(
            label: 'OUVRIR PORTE MAGNÉTIQUE',
            icon: Icons.lock_open_rounded,
            color: AppTheme.primaryRed,
            onPressed: () {},
          ),
          const Gap(12),
          _ActuatorButton(
            label: 'DÉCLENCHER MACHINE À FUMÉE',
            icon: Icons.cloud_rounded,
            color: Colors.blue,
            onPressed: () {},
          ),
          const Gap(12),
          _ActuatorButton(
            label: 'RESET ÉNIGME DES SYMBOLES',
            icon: Icons.refresh_rounded,
            color: AppTheme.successGreen,
            onPressed: () {},
          ),
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
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigurationTerminal extends StatefulWidget {
  @override
  State<_ConfigurationTerminal> createState() => _ConfigurationTerminalState();
}

class _ConfigurationTerminalState extends State<_ConfigurationTerminal> {
  double _threshold = 75.0;
  int _timer = 60;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_input_component_rounded, color: AppTheme.primaryRed, size: 20),
              const Gap(12),
              const Text(
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
          _ConfigSlider(
            label: 'SEUIL CAPTEUR SONORE (dB)',
            value: _threshold,
            min: 0,
            max: 120,
            onChanged: (val) => setState(() => _threshold = val),
          ),
          const Gap(24),
          _ConfigInput(
            label: 'TEMPS LIMITE ÉNIGME (SEC)',
            value: _timer.toString(),
            onChanged: (val) => setState(() => _timer = int.tryParse(val) ?? _timer),
          ),
          const Gap(32),
          PrimaryButton(
            label: 'APPLIQUER MODIFICATIONS',
            icon: Icons.save_rounded,
            onPressed: () {},
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
            fillColor: Colors.black.withOpacity(0.3),
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
