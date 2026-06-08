import 'dart:convert';
import 'package:escape_room_admin/core/services/mqtt_service.dart';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SwitchesEnigmaWidget extends StatefulWidget {
  const SwitchesEnigmaWidget({super.key});

  @override
  State<SwitchesEnigmaWidget> createState() => _SwitchesEnigmaWidgetState();
}

class _SwitchesEnigmaWidgetState extends State<SwitchesEnigmaWidget> {
  String _statusText = 'En attente...';
  bool _isSolved = false;

  // État actuel des 9 boutons reçu de l'ESP32 (0 ou 1)
  List<int> _currentState = List.filled(9, 0);
  // Combinaison correcte (optionnel : pour affichage comparatif)
  List<int> _targetState = List.filled(9, 0);
  bool _hasTarget = false;

  @override
  void initState() {
    super.initState();
    try {
      MqttService().subscribe('escape/room1/enigma/switches/status', (payload) {
        if (mounted) {
          setState(() => _processPayload(payload));
        }
      });
    } catch (e) {
      print('Erreur souscription switches: $e');
    }
  }

  void _processPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      final status = data['status'] as String? ?? '';

      if (status == 'solved') {
        _isSolved = true;
        _statusText = 'RÉSOLU ✓';
      } else if (status == 'reset') {
        _isSolved = false;
        _statusText = 'En attente...';
        _currentState = List.filled(9, 0);
      } else if (status == 'progress') {
        _isSolved = false;
        final raw = data['current'] as List<dynamic>? ?? [];
        _currentState = raw.map((e) => (e as int?) ?? 0).toList();
        if (_currentState.length != 9) _currentState = List.filled(9, 0);
        _statusText = 'En cours...';
      }

      // Récupérer la cible si l'ESP la renvoie
      if (data.containsKey('target')) {
        final t = data['target'] as List<dynamic>;
        _targetState = t.map((e) => (e as int?) ?? 0).toList();
        _hasTarget = true;
      }
    } catch (e) {
      _statusText = payload;
    }
  }

  void _bypass() {
    try {
      MqttService().publish('escape/room1/enigma/switches/command', '{"action":"bypass"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur MQTT: $e')));
    }
  }

  void _reset() {
    try {
      MqttService().publish('escape/room1/enigma/switches/command', '{"action":"reset"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur MQTT: $e')));
    }
  }

  Color _cellColor(int index) {
    final isOn = _currentState[index] == 1;
    if (_isSolved) return AppTheme.successGreen.withOpacity(0.3);
    if (_hasTarget) {
      final correct = _currentState[index] == _targetState[index];
      if (isOn && correct) return AppTheme.successGreen.withOpacity(0.4);
      if (isOn && !correct) return AppTheme.primaryRed.withOpacity(0.4);
    }
    return isOn
        ? AppTheme.warningOrange.withOpacity(0.3)
        : AppTheme.primaryBlack;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.toggle_on_rounded,
                    color: AppTheme.warningOrange, size: 20),
              ),
              const Gap(12),
              const Text(
                'Interrupteurs Binaires',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSolved
                      ? AppTheme.successGreen
                      : AppTheme.warningOrange,
                  boxShadow: [
                    BoxShadow(
                      color: (_isSolved
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange)
                          .withOpacity(0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ],
          ),
          const Gap(10),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.grayBorder, width: 0.5),
            ),
            child: Text(
              _statusText.toUpperCase(),
              style: TextStyle(
                color: _isSolved ? AppTheme.successGreen : AppTheme.grayText,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const Gap(10),

          // Grille 3x3
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 3,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final isOn = _currentState[index] == 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _cellColor(index),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOn
                        ? (_isSolved
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange)
                        : AppTheme.grayBorder,
                    width: isOn ? 1.5 : 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isOn ? '1' : '0',
                  style: TextStyle(
                    color: isOn ? AppTheme.white : AppTheme.grayText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
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
                    side: BorderSide(
                        color: AppTheme.grayText.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      Gap(4),
                      Text('RESET',
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _bypass,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    side: BorderSide(
                        color: AppTheme.successGreen.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fast_forward_rounded, size: 18),
                      Gap(4),
                      Text('BYPASS',
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
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


