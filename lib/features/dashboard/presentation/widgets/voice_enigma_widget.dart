import 'dart:convert';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:escape_room_admin/features/admin/data/enigma_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceEnigmaWidget extends ConsumerStatefulWidget {
  const VoiceEnigmaWidget({super.key});

  @override
  ConsumerState<VoiceEnigmaWidget> createState() => _VoiceEnigmaWidgetState();
}

class _VoiceEnigmaWidgetState extends ConsumerState<VoiceEnigmaWidget> {
  String _statusText = 'En attente...';
  bool _isSuccess = false;
  String _heardText = '---';
  String _currentChallenge = '---'; // challenge currently stored by python script
  String? _selectedPhrase; // for the dropdown
  
  @override
  void initState() {
    super.initState();
    try {
      PublicMqttService().subscribe('rpi/result', (payload) {
        if (mounted) setState(() => _processPayload(payload));
      });
    } catch (e) {
      print('Erreur souscription voice: $e');
    }
  }

  void _processPayload(String payload) {
    print('🎙️ [VoiceEnigma] Reçu de rpi/result : $payload');
    try {
      final data = jsonDecode(payload);
      
      if (data.containsKey('status') && data['status'] == 'success') {
        _isSuccess = true;
        if (data.containsKey('heard')) _heardText = data['heard'] as String;
        if (data.containsKey('challenge')) _currentChallenge = data['challenge'] as String;
        _statusText = 'SUCCÈS - MOT DE PASSE RECONNU';
        print('🎙️ [VoiceEnigma] Succès validé !');
      } else {
        print('🎙️ [VoiceEnigma] Status non-success ou payload invalide');
      }
    } catch (e) {
      print('🎙️ [VoiceEnigma] Erreur JSON Parse: $e');
      _statusText = 'Erreur JSON';
    }
  }

  void _reset() {
    setState(() {
      _isSuccess = false;
      _heardText = '---';
      _statusText = 'En attente...';
    });
    // Optional: send an empty or specific reset challenge to the python script if needed.
    // MqttService().publish('rpi/challenge', ''); 
  }

  void _sendManualChallenge() {
    if (_selectedPhrase != null && _selectedPhrase!.isNotEmpty) {
      PublicMqttService().publish('rpi/challenge', _selectedPhrase!);
      setState(() {
        _currentChallenge = _selectedPhrase!;
        _isSuccess = false;
        _heardText = '---';
        _statusText = 'DÉFI ENVOYÉ. EN ATTENTE...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String defaultPhrases = "open the door now, i know the word, get me out fast, security is now disabled, secret code is accepted, end of the game, unlock the main system, access granted for all, the key is free, launch the central program";
    
    final enigmasState = ref.watch(enigmaProvider).value;
    List<String> phrases = defaultPhrases.split(',').map((e) => e.trim()).toList();
    if (enigmasState != null) {
      final voiceEnigma = enigmasState.enigmas.where((e) => e.type == 'Reconnaissance Vocale').firstOrNull;
      if (voiceEnigma != null && voiceEnigma.configuration.containsKey('target_phrase')) {
        final configPhrase = voiceEnigma.configuration['target_phrase'] as String;
        if (configPhrase.trim().isNotEmpty) {
          final customPhrases = configPhrase.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          // Combine Database phrases + Default phrases (using Set to remove duplicates)
          phrases = {...customPhrases, ...phrases}.toList();
        }
      }
    }
    
    // Ensure _selectedPhrase is initially set to the first option if available
    if (_selectedPhrase == null && phrases.isNotEmpty) {
      _selectedPhrase = phrases.first;
    }
    if (!phrases.contains(_selectedPhrase) && phrases.isNotEmpty) {
      _selectedPhrase = phrases.first;
    }

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
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: Colors.purpleAccent, size: 20),
              ),
              const Gap(12),
              const Text('Reconnaissance Vocale',
                  style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
              const Spacer(),
              // Status indicator
              Icon(
                _isSuccess ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: _isSuccess ? AppTheme.successGreen : AppTheme.grayText,
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
                color: _isSuccess 
                    ? AppTheme.successGreen.withOpacity(0.5) 
                    : AppTheme.primaryRed.withOpacity(0.5), 
                width: 0.5
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MOT CIBLE', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      const Gap(4),
                      Text(
                        _currentChallenge,
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(8),
                      const Text('DERNIER PHRASE ENTENDUE', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      const Gap(4),
                      Text(
                        _heardText.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('RÉSULTAT', style: TextStyle(color: AppTheme.grayText, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(
                      _isSuccess ? 'Validé' : 'Erreur',
                      style: TextStyle(
                        color: _isSuccess ? AppTheme.successGreen : AppTheme.primaryRed,
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

          // Dropdown & Action to send phrase
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.grayBorder, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPhrase,
                      dropdownColor: AppTheme.primaryBlack,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.purpleAccent),
                      isExpanded: true,
                      style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold),
                      items: phrases.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPhrase = val);
                      },
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: _sendManualChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                    foregroundColor: Colors.purpleAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5)),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('ENVOYER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const Gap(16),

          // Status Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSuccess 
                  ? AppTheme.successGreen.withOpacity(0.4) 
                  : AppTheme.primaryRed.withOpacity(0.4), 
                width: 0.5
              ),
            ),
            child: Text(
              _statusText,
              style: TextStyle(
                color: _isSuccess ? AppTheme.successGreen : AppTheme.warningOrange,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(16),

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
                    Text('RÉINITIALISER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
