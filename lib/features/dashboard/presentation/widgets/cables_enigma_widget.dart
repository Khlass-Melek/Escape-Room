import 'package:escape_room_admin/core/services/mqtt_service.dart';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:convert';

class CablesEnigmaWidget extends StatefulWidget {
  const CablesEnigmaWidget({super.key});

  @override
  State<CablesEnigmaWidget> createState() => _CablesEnigmaWidgetState();
}

class _CablesEnigmaWidgetState extends State<CablesEnigmaWidget> {
  String _status = "En attente...";
  int _correctCables = 0;
  int _totalCables = 3;

  @override
  void initState() {
    super.initState();
    // Souscrire aux statuts de l'énigme des câbles
    try {
      MqttService().subscribe('escape/room1/enigma/cables/status', (payload) {
        if (mounted) {
          setState(() {
            _processPayload(payload);
          });
        }
      });
    } catch (e) {
      print("Erreur de souscription MQTT: $e");
    }
  }

  void _processPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data.containsKey('status')) {
        _status = data['status'];
      }
      if (data.containsKey('correctCount')) {
        _correctCables = data['correctCount'];
        _totalCables = data['total'] ?? 3;
        _status = "Progression: $_correctCables / $_totalCables";
      }
    } catch (e) {
      _status = payload; // Afficher le payload brut si ce n'est pas du JSON valide
    }
  }

  void _bypassEnigma() {
    try {
      MqttService().publish(
        'escape/room1/enigma/cables/command',
        '{"action":"bypass"}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur MQTT: $e')),
      );
    }
  }

  void _resetEnigma() {
    try {
      MqttService().publish(
        'escape/room1/enigma/cables/command',
        '{"action":"reset"}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur MQTT: $e')),
      );
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
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cable_rounded, color: AppTheme.primaryRed, size: 20),
              ),
              const Gap(12),
              const Text(
                'Énigme des Câbles',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Gap(24),

          // Status Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grayBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STATUS:',
                      style: TextStyle(
                        color: AppTheme.grayText,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _status.contains('solved') ? AppTheme.successGreen : AppTheme.warningOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  _status.toUpperCase(),
                  style: TextStyle(
                    color: _status.contains('solved') ? AppTheme.successGreen : AppTheme.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_status.contains('Progression')) ...[
                  const Gap(8),
                  LinearProgressIndicator(
                    value: _totalCables > 0 ? _correctCables / _totalCables : 0,
                    backgroundColor: AppTheme.secondaryBlack,
                    color: AppTheme.successGreen,
                    minHeight: 6,
                  ),
                ]
              ],
            ),
          ),
          
          const Gap(24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetEnigma,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.grayText,
                    side: BorderSide(color: AppTheme.grayText.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      Gap(4),
                      Text('RESET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _bypassEnigma,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    side: BorderSide(color: AppTheme.successGreen.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fast_forward_rounded, size: 20),
                      Gap(4),
                      Text('BYPASS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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


