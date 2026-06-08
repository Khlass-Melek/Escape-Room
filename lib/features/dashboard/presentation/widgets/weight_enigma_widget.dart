import 'dart:convert';
import 'package:escape_room_admin/core/services/mqtt_service.dart';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class WeightEnigmaWidget extends StatefulWidget {
  const WeightEnigmaWidget({super.key});

  @override
  State<WeightEnigmaWidget> createState() => _WeightEnigmaWidgetState();
}

class _WeightEnigmaWidgetState extends State<WeightEnigmaWidget> {
  String _statusText = 'En attente...';
  bool _isSolved = false;
  double _currentWeight = 0;   // en grammes
  double _targetWeight = 0;    // en grammes
  double _margin = 20;         // ±20g par défaut
  bool _isLedOn = false;

  @override
  void initState() {
    super.initState();
    try {
      MqttService().subscribe('escape/room1/enigma/weight/status', (payload) {
        if (mounted) setState(() => _processPayload(payload));
      });
    } catch (e) {
      print('Erreur souscription weight: $e');
    }
  }

  void _processPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      final status = data['status'] as String? ?? '';

      if (data.containsKey('current_g'))  _currentWeight = (data['current_g'] as num).toDouble();
      if (data.containsKey('target_g'))   _targetWeight  = (data['target_g']  as num).toDouble();
      if (data.containsKey('margin_g'))   _margin        = (data['margin_g']  as num).toDouble();
      if (data.containsKey('led'))        _isLedOn       = data['led'] as bool? ?? false;

      if (status == 'solved') {
        _isSolved = true;
        _statusText = 'Poids correct ✓';
        _isLedOn = true;
      } else if (status == 'reset') {
        _isSolved = false;
        _statusText = 'En attente...';
        _currentWeight = 0;
        _isLedOn = false;
      } else if (status == 'progress') {
        _isSolved = false;
        final diff = (_currentWeight - _targetWeight).abs();
        if (_targetWeight > 0) {
          _statusText = 'Actuel: ${_currentWeight.toStringAsFixed(0)}g | Cible: ${_targetWeight.toStringAsFixed(0)}g ±${_margin.toStringAsFixed(0)}g';
        } else {
          _statusText = 'Actuel: ${_currentWeight.toStringAsFixed(0)}g | Cible non définie';
        }
      }
    } catch (e) {
      _statusText = payload;
    }
  }

  void _bypass() {
    try {
      MqttService().publish('escape/room1/enigma/weight/command', '{"action":"bypass"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _reset() {
    try {
      MqttService().publish('escape/room1/enigma/weight/command', '{"action":"reset"}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // Calcule l'écart normalisé pour la barre de précision
  double get _accuracy {
    if (_targetWeight <= 0) return 0;
    final diff = (_currentWeight - _targetWeight).abs();
    if (diff >= _targetWeight) return 0;
    return (1 - (diff / _targetWeight)).clamp(0.0, 1.0);
  }

  Color get _barColor {
    if (_isSolved || _isLedOn) return AppTheme.successGreen;
    if (_accuracy > 0.85) return AppTheme.warningOrange;
    return AppTheme.primaryRed;
  }

  @override
  Widget build(BuildContext context) {
    final diff = _targetWeight > 0 ? (_currentWeight - _targetWeight) : 0.0;
    final inRange = _targetWeight > 0 && diff.abs() <= _margin;

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
                  color: Colors.blueGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.scale_rounded, color: Colors.blueGrey, size: 20),
              ),
              const Gap(12),
              const Text('Capteur de Poids',
                  style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
              const Spacer(),
              // LED indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLedOn ? AppTheme.successGreen : AppTheme.primaryRed,
                  boxShadow: [BoxShadow(color: (_isLedOn ? AppTheme.successGreen : AppTheme.primaryRed).withOpacity(0.6), blurRadius: 6)],
                ),
              ),
            ],
          ),
          const Gap(20),

          // Poids courant
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: inRange ? AppTheme.successGreen.withOpacity(0.5) : AppTheme.grayBorder, width: 0.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Poids actuel
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('POIDS ACTUEL', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        const Gap(4),
                        Text(
                          '${_currentWeight.toStringAsFixed(0)}g',
                          style: TextStyle(
                            color: inRange ? AppTheme.successGreen : AppTheme.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    // Flèche
                    Icon(Icons.arrow_forward_rounded, color: AppTheme.grayText.withOpacity(0.4), size: 20),
                    // Poids cible
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CIBLE ± MARGE', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        const Gap(4),
                        Text(
                          _targetWeight > 0 ? '${_targetWeight.toStringAsFixed(0)} ±${_margin.toStringAsFixed(0)}g' : '—',
                          style: TextStyle(
                            color: AppTheme.warningOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(16),

                // Barre de précision
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PRÉCISION', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        Text(
                          _targetWeight > 0 ? '${(_accuracy * 100).toStringAsFixed(0)}%' : '--',
                          style: TextStyle(color: _barColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Gap(6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _accuracy,
                        backgroundColor: AppTheme.secondaryBlack,
                        color: _barColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),

                // Écart
                if (_targetWeight > 0) ...[
                  const Gap(8),
                  Text(
                    diff >= 0 ? '+${diff.toStringAsFixed(0)}g' : '${diff.toStringAsFixed(0)}g',
                    style: TextStyle(
                      color: inRange ? AppTheme.successGreen : AppTheme.grayText,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
              border: Border.all(color: _isSolved ? AppTheme.successGreen.withOpacity(0.4) : AppTheme.grayBorder, width: 0.5),
            ),
            child: Text(
              _statusText.toUpperCase(),
              style: TextStyle(
                color: _isSolved ? AppTheme.successGreen : AppTheme.grayText,
                fontFamily: 'monospace',
                fontSize: 9,
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
                    side: BorderSide(color: AppTheme.successGreen.withOpacity(0.5)),
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


