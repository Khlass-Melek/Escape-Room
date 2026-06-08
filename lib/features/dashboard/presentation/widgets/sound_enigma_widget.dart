import 'dart:convert';
import 'package:escape_room_admin/core/services/mqtt_service.dart';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SoundEnigmaWidget extends StatefulWidget {
  const SoundEnigmaWidget({super.key});

  @override
  State<SoundEnigmaWidget> createState() => _SoundEnigmaWidgetState();
}

class _SoundEnigmaWidgetState extends State<SoundEnigmaWidget> {
  String _statusText = 'En attente...';
  int _currentState = 0; // 0=Normal, 1=Flash, 2=Off
  bool _isCalm = true;
  bool _isLightOn = true;
  int _amplitude = 0;
  
  @override
  void initState() {
    super.initState();
    try {
      MqttService().subscribe('escape/room1/enigma/calm/status', (payload) {
        if (mounted) setState(() => _processPayload(payload));
      });
    } catch (e) {
      print('Erreur souscription sound: $e');
    }
  }

  void _processPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      
      if (data.containsKey('state')) _currentState = data['state'] as int;
      if (data.containsKey('isCalm')) _isCalm = data['isCalm'] as bool;
      if (data.containsKey('lightOn')) _isLightOn = data['lightOn'] as bool;
      if (data.containsKey('amplitude')) _amplitude = data['amplitude'] as int;

      if (_currentState == 0) {
        _statusText = 'NORMAL - AMBIANCE CALME';
      } else if (_currentState == 1) {
        _statusText = 'PÉNALITÉ - NIVEAU 1 (FLASH)';
      } else if (_currentState == 2) {
        _statusText = 'PÉNALITÉ - NIVEAU 2 (ÉTEINT)';
      }
    } catch (e) {
      _statusText = 'Erreur JSON';
    }
  }

  void _reset() {
    try {
      MqttService().publish('escape/room1/enigma/calm/command', '{"action":"reset"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.blue, size: 20),
              ),
              const Gap(12),
              const Text('Capteur Sonore',
                  style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
              const Spacer(),
              // Light Bulb indicator
              Icon(
                _isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                color: _isLightOn ? Colors.yellow : AppTheme.grayText,
                size: 24,
              ),
            ],
          ),
          const Gap(20),

          // Visualisation de l'état
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentState == 0 
                    ? AppTheme.successGreen.withOpacity(0.5) 
                    : AppTheme.primaryRed.withOpacity(0.5), 
                width: 0.5
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ETAT AMPOULE', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(
                      _isLightOn ? 'ALLUMÉE' : 'ÉTEINTE',
                      style: TextStyle(
                        color: _isLightOn ? Colors.yellow : AppTheme.grayText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Gap(8),
                    const Text('AMPLITUDE (dB)', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(
                      '$_amplitude',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('BRUIT DÉTECTÉ', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(
                      !_isCalm ? 'FORT !' : 'Calme',
                      style: TextStyle(
                        color: !_isCalm ? AppTheme.primaryRed : AppTheme.successGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(12),

          // Status Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentState == 0 
                  ? AppTheme.successGreen.withOpacity(0.4) 
                  : AppTheme.primaryRed.withOpacity(0.4), 
                width: 0.5
              ),
            ),
            child: Text(
              _statusText,
              style: TextStyle(
                color: _currentState == 0 ? AppTheme.successGreen : AppTheme.warningOrange,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.grayText,
                    side: BorderSide(color: AppTheme.grayText.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    Gap(4),
                    Text('PARDONNER (RESET)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


