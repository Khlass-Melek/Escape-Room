import 'dart:convert';
import 'package:escape_room_admin/core/services/public_mqtt_service.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TicTacToeEnigmaWidget extends StatefulWidget {
  const TicTacToeEnigmaWidget({super.key});

  @override
  State<TicTacToeEnigmaWidget> createState() => _TicTacToeEnigmaWidgetState();
}

class _TicTacToeEnigmaWidgetState extends State<TicTacToeEnigmaWidget> {
  String _state = 'disconnected'; // locked, waiting, game, revenge, disconnected
  String _turn = '';
  List<List<String>> _board = [
    ['', '', ''],
    ['', '', ''],
    ['', '', '']
  ];
  bool _opponentFound = false;

  @override
  void initState() {
    super.initState();
    try {
      PublicMqttService().subscribe('escape/room1/enigma/tictactoe/status', (payload) {
        if (mounted) setState(() => _processPayload(payload));
      });
      // Subscribe to RPI moves just in case we need to sync, but status sends the whole board anyway.
    } catch (e) {
      print('Erreur souscription tictactoe: $e');
    }
  }

  void _processPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data.containsKey('state')) _state = data['state'].toString();
      if (data.containsKey('turn')) _turn = data['turn'].toString();
      if (data.containsKey('opponent_found')) _opponentFound = data['opponent_found'] as bool;
      
      if (data.containsKey('board')) {
        final rawBoard = data['board'] as List<dynamic>;
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
             _board[r][c] = rawBoard[r][c].toString();
          }
        }
      }
    } catch (e) {
      print('JSON error in TicTacToe: $e');
    }
  }

  void _unlock() {
    PublicMqttService().publish('escape/room1/enigma/tictactoe/command', '{"action":"unlock"}');
  }

  void _reset() {
    PublicMqttService().publish('escape/room1/enigma/tictactoe/command', '{"action":"reset"}');
  }

  void _acceptMatch() {
    PublicMqttService().publish('escape/room1/enigma/tictactoe/accept', '{"action":"accept"}');
  }

  void _playMove(int row, int col) {
    if (_state != 'game' || !_opponentFound || _turn != 'X') return; // We play as X since RPI assigns itself O for revenge/bot? Actually RPI plays O.
    if (_board[row][col] != '') return; // Cell taken

    // Send move to python script
    PublicMqttService().publish('escape/room1/enigma/tictactoe/move/web', jsonEncode({'row': row, 'col': col}));
  }

  Widget _buildGrid() {
    return Column(
      children: List.generate(3, (r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (c) {
            String cell = _board[r][c];
            return GestureDetector(
              onTap: () => _playMove(r, c),
              child: Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  border: Border.all(color: AppTheme.grayBorder, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    cell,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cell == 'X' ? AppTheme.primaryRed : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPvP = _state == 'game' && _opponentFound;
    bool isPlaying = (_state == 'game' || _state == 'revenge');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _state == 'game' && _opponentFound ? AppTheme.warningOrange : AppTheme.grayBorder, width: _state == 'game' && _opponentFound ? 1.5 : 0.5),
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
                child: const Icon(Icons.grid_3x3_rounded, color: Colors.purple, size: 20),
              ),
              const Gap(12),
              const Text('Tic Tac Toe (XO)',
                  style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
              const Spacer(),
              // Mode Indicator
              if (_opponentFound)
                 const Text('PvP ACTIF', style: TextStyle(color: AppTheme.warningOrange, fontSize: 10, fontWeight: FontWeight.bold)),
              if (!_opponentFound && (_state == 'game' || _state == 'revenge'))
                 const Text('CONTRE IA', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(20),

          // Main Content
          if (_state == 'locked') ...[
            const Icon(Icons.lock_rounded, color: AppTheme.grayText, size: 40),
            const Gap(12),
            const Text('SYSTÈME VERROUILLÉ DANS LA SALLE', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grayText, fontWeight: FontWeight.bold)),
            const Gap(20),
            PrimaryButton(
               label: 'DÉVERROUILLER L\'ÉNIGME',
               icon: Icons.lock_open,
               onPressed: _unlock,
               color: AppTheme.primaryRed,
            ),
          ] else if (_state == 'waiting') ...[
            const CircularProgressIndicator(color: AppTheme.warningOrange),
            const Gap(12),
            const Text('RECHERCHE D\'ADVERSAIRE (10s)...', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold)),
            const Gap(20),
            PrimaryButton(
               label: 'REJOINDRE (PvP)',
               icon: Icons.sports_esports,
               onPressed: _acceptMatch,
               color: AppTheme.warningOrange,
            ),
          ] else if (isPlaying) ...[
            _buildGrid(),
            const Gap(16),
            if (isPvP)
               Text(
                 _turn == 'X' ? 'C\'est À VOUS de jouer (X) !' : 'Le Joueur (O) réfléchit...', 
                 textAlign: TextAlign.center, 
                 style: TextStyle(
                   color: _turn == 'X' ? AppTheme.successGreen : AppTheme.grayText,
                   fontWeight: FontWeight.bold,
                   fontSize: 12
                 )
               )
            else
               Text(
                 'Mode IA actif (Revenge : ${_state == "revenge"})', 
                 textAlign: TextAlign.center, 
                 style: const TextStyle(color: AppTheme.grayText, fontSize: 10)
               ),
            const Gap(20),
            OutlinedButton(
               onPressed: _reset,
               style: OutlinedButton.styleFrom(
                 foregroundColor: AppTheme.grayText,
                 side: BorderSide(color: AppTheme.grayText.withOpacity(0.5)),
                 padding: const EdgeInsets.symmetric(vertical: 14),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               child: const Text('RÉINITIALISER (VERROUILLER)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
             const Text('En attente de connexion avec le RPi...', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grayText)),
          ],
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const PrimaryButton(
      {super.key, required this.label, required this.icon, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}
