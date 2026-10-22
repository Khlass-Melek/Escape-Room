import 'dart:convert';
import 'package:escape_room_admin/core/services/mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlantEnigmaWidget extends StatefulWidget {
  const PlantEnigmaWidget({super.key});

  @override
  State<PlantEnigmaWidget> createState() => _PlantEnigmaWidgetState();
}

class _PlantEnigmaWidgetState extends State<PlantEnigmaWidget> {
  String _statusText = 'En attente...';
  bool _isSolved = false;
  int _humidity = 0;
  int _threshold = 50;
  String _ledState = 'red'; // 'red', 'yellow', 'green'

  @override
  void initState() {
    super.initState();
    try {
      MqttService().subscribe('escape/room1/enigma/plant/status', (payload) {
        if (mounted) setState(() => _processPayload(payload));
      });
    } catch (e) {
      print('Erreur souscription plant: $e');
    }
  }

  void _processPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      final status = data['status'] as String? ?? '';

      if (data.containsKey('humidity')) {
        _humidity = (data['humidity'] as num?)?.toInt() ?? 0;
      }
      if (data.containsKey('threshold')) {
        _threshold = (data['threshold'] as num?)?.toInt() ?? 50;
      }
      if (data.containsKey('led')) {
        _ledState = data['led'] as String? ?? 'red';
      }

      if (status == 'solved') {
        _isSolved = true;
        _statusText = 'Plante arrosée ✓';
        _ledState = 'green';
      } else if (status == 'reset') {
        _isSolved = false;
        _statusText = 'En attente...';
        _humidity = 0;
        _ledState = 'red';
      } else if (status == 'progress') {
        _isSolved = false;
        _statusText = 'Humidité : $_humidity%  (seuil : $_threshold%)';
      }
    } catch (e) {
      _statusText = payload;
    }
  }

  void _bypass() {
    try {
      MqttService().publish('escape/room1/enigma/plant/command', '{"action":"bypass"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _reset() {
    try {
      MqttService().publish('escape/room1/enigma/plant/command', '{"action":"reset"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Color get _ledColor {
    switch (_ledState) {
      case 'green': return AppTheme.successGreen;
      case 'yellow': return AppTheme.warningOrange;
      default: return AppTheme.primaryRed;
    }
  }

  Color get _barColor {
    if (_humidity >= _threshold) return AppTheme.successGreen;
    if (_humidity >= _threshold * 0.6) return AppTheme.warningOrange;
    return AppTheme.primaryRed;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_humidity / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
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
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_florist_rounded, color: AppTheme.successGreen, size: 20),
              ),
              const Gap(12),
              const Text(
                'Plante — Capteur d\'eau',
                style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
              ),
              const Spacer(),
              // LED indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ledColor,
                  boxShadow: [BoxShadow(color: _ledColor.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)],
                ),
              ),
            ],
          ),
          const Gap(20),

          // Humidity Gauge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grayBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('HUMIDITÉ', style: TextStyle(color: AppTheme.grayText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(
                      '$_humidity%',
                      style: TextStyle(
                        color: _barColor,
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlack,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Filled bar
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 500),
                      widthFactor: progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: _barColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: _barColor.withValues(alpha: 0.4), blurRadius: 4)],
                        ),
                      ),
                    ),
                    // Threshold marker
                    Positioned(
                      left: MediaQuery.of(context).size.width * _threshold / 100 * 0.3,
                      child: Container(
                        width: 2,
                        height: 12,
                        color: AppTheme.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0%', style: TextStyle(color: AppTheme.grayText, fontSize: 9)),
                    Text(
                      'Seuil: $_threshold%',
                      style: TextStyle(
                        color: AppTheme.warningOrange.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('100%', style: TextStyle(color: AppTheme.grayText, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const Gap(12),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isSolved ? AppTheme.successGreen.withValues(alpha: 0.4) : AppTheme.grayBorder, width: 0.5),
            ),
            child: Text(
              _statusText.toUpperCase(),
              style: TextStyle(
                color: _isSolved ? AppTheme.successGreen : AppTheme.grayText,
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
                    side: BorderSide(color: AppTheme.grayText.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    Gap(4),
                    Text('RESET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _bypass,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    side: BorderSide(color: AppTheme.successGreen.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.fast_forward_rounded, size: 18),
                    Gap(4),
                    Text('BYPASS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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


