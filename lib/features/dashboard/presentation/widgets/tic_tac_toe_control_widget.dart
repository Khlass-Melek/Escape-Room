import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum TicTacToeMode { gmVsPlayer, aiVsPlayer }

enum TicTacToeStatus { waitingConnection, connected, disconnected, playing }

class TicTacToeState {
  final List<String> board; // '' | 'X' | 'O'
  final String currentTurn; // 'X' | 'O'
  final String? winner; // null | 'X' | 'O' | 'draw'
  final bool isGameActive;
  final TicTacToeMode mode;
  final TicTacToeStatus connectionStatus;
  final String aiDifficulty; // 'Facile' | 'Moyen' | 'Difficile' | 'Imbattable'

  const TicTacToeState({
    required this.board,
    this.currentTurn = 'X',
    this.winner,
    this.isGameActive = false,
    this.mode = TicTacToeMode.aiVsPlayer,
    this.connectionStatus = TicTacToeStatus.waitingConnection,
    this.aiDifficulty = 'Moyen',
  });

  TicTacToeState copyWith({
    List<String>? board,
    String? currentTurn,
    String? winner,
    bool? isGameActive,
    TicTacToeMode? mode,
    TicTacToeStatus? connectionStatus,
    String? aiDifficulty,
  }) {
    return TicTacToeState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      winner: winner ?? this.winner,
      isGameActive: isGameActive ?? this.isGameActive,
      mode: mode ?? this.mode,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME LOGIC
// ─────────────────────────────────────────────────────────────────────────────

class TicTacToeLogic {
  static const List<List<int>> _winPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
    [0, 4, 8], [2, 4, 6],            // diags
  ];

  static String? checkWinner(List<String> board) {
    for (final pattern in _winPatterns) {
      final a = board[pattern[0]];
      if (a.isNotEmpty && a == board[pattern[1]] && a == board[pattern[2]]) {
        return a;
      }
    }
    if (board.every((c) => c.isNotEmpty)) return 'draw';
    return null;
  }

  static List<int> getWinningCells(List<String> board) {
    for (final pattern in _winPatterns) {
      final a = board[pattern[0]];
      if (a.isNotEmpty && a == board[pattern[1]] && a == board[pattern[2]]) {
        return pattern;
      }
    }
    return [];
  }

  static int? getAiMove(List<String> board, String aiSymbol, String difficulty) {
    final playerSymbol = aiSymbol == 'O' ? 'X' : 'O';
    final empty = <int>[];
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) empty.add(i);
    }
    if (empty.isEmpty) return null;

    if (difficulty == 'Facile') {
      return empty[Random().nextInt(empty.length)];
    }

    if (difficulty == 'Moyen') {
      // 50% chance of random
      if (Random().nextBool()) return empty[Random().nextInt(empty.length)];
    }

    // Try to win
    for (final i in empty) {
      final test = List<String>.from(board)..[i] = aiSymbol;
      if (checkWinner(test) == aiSymbol) return i;
    }

    // Block player win
    for (final i in empty) {
      final test = List<String>.from(board)..[i] = playerSymbol;
      if (checkWinner(test) == playerSymbol) return i;
    }

    if (difficulty == 'Moyen') {
      return empty[Random().nextInt(empty.length)];
    }

    // Minimax for Difficile / Imbattable
    int bestScore = -1000;
    int bestMove = empty.first;
    for (final i in empty) {
      final test = List<String>.from(board)..[i] = aiSymbol;
      final score = _minimax(test, false, aiSymbol, playerSymbol, 0, difficulty == 'Imbattable' ? 9 : 4);
      if (score > bestScore) {
        bestScore = score;
        bestMove = i;
      }
    }
    return bestMove;
  }

  static int _minimax(List<String> board, bool isMaximizing, String aiSymbol, String playerSymbol, int depth, int maxDepth) {
    final winner = checkWinner(board);
    if (winner == aiSymbol) return 10 - depth;
    if (winner == playerSymbol) return depth - 10;
    if (winner == 'draw' || depth >= maxDepth) return 0;

    final empty = <int>[];
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) empty.add(i);
    }

    if (isMaximizing) {
      int best = -1000;
      for (final i in empty) {
        final test = List<String>.from(board)..[i] = aiSymbol;
        best = max(best, _minimax(test, false, aiSymbol, playerSymbol, depth + 1, maxDepth));
      }
      return best;
    } else {
      int best = 1000;
      for (final i in empty) {
        final test = List<String>.from(board)..[i] = playerSymbol;
        best = min(best, _minimax(test, true, aiSymbol, playerSymbol, depth + 1, maxDepth));
      }
      return best;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Drop this into [RoomFocusView] or [DashboardPage] for XO enigma type.
/// Usage:
///   TicTacToeControlWidget(
///     enigmaName: _linkedEnigma!['name'] ?? 'Tic Tac Toe',
///     aiDifficulty: _linkedEnigma!['config']?['ia_difficulty'] ?? 'Moyen',
///     raspberryPiIp: _linkedEnigma!['config']?['raspberry_pi_ip'] ?? widget.cameraId,
///   )
class TicTacToeControlWidget extends StatefulWidget {
  final String enigmaName;
  final String aiDifficulty;
  final String? raspberryPiIp;

  const TicTacToeControlWidget({
    super.key,
    required this.enigmaName,
    this.aiDifficulty = 'Moyen',
    this.raspberryPiIp,
  });

  @override
  State<TicTacToeControlWidget> createState() => _TicTacToeControlWidgetState();
}

class _TicTacToeControlWidgetState extends State<TicTacToeControlWidget>
    with TickerProviderStateMixin {
  late TicTacToeState _gameState;
  Timer? _connectionRetryTimer;
  Timer? _aiMoveTimer;
  late AnimationController _pulseController;
  late AnimationController _winController;
  final List<AnimationController> _cellControllers = [];

  // Theme constants (mirrors AppTheme)
  static const Color _primaryBlack = Color(0xFF0D0D0D);
  static const Color _secondaryBlack = Color(0xFF1A1A1A);
  static const Color _primaryRed = Color(0xFFDC143C);
  static const Color _secondaryRed = Color(0xFF8B0000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _grayBorder = Color(0xFF2D2D2D);
  static const Color _grayText = Color(0xFFB8B8B8);
  static const Color _successGreen = Color(0xFF28A745);
  static const Color _warningOrange = Color(0xFFFFA500);

  @override
  void initState() {
    super.initState();
    _gameState = TicTacToeState(
      board: List.filled(9, ''),
      aiDifficulty: widget.aiDifficulty,
      connectionStatus: TicTacToeStatus.waitingConnection,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    for (int i = 0; i < 9; i++) {
      _cellControllers.add(
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300)),
      );
    }

    _simulateConnectionAttempt();
  }

  @override
  void dispose() {
    _connectionRetryTimer?.cancel();
    _aiMoveTimer?.cancel();
    _pulseController.dispose();
    _winController.dispose();
    for (final c in _cellControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Connection simulation ──────────────────────────────────────────────────

  void _simulateConnectionAttempt() {
    // Simulate a connection attempt to the Raspberry Pi
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      // In a real implementation: try WebSocket/HTTP to widget.raspberryPiIp
      // For now we simulate a failed connection → AI fallback
      setState(() {
        _gameState = _gameState.copyWith(
          connectionStatus: TicTacToeStatus.disconnected,
          mode: TicTacToeMode.aiVsPlayer, // Fallback to AI
        );
      });
    });
  }

  void _retryConnection() {
    setState(() {
      _gameState = _gameState.copyWith(
        connectionStatus: TicTacToeStatus.waitingConnection,
      );
    });
    _simulateConnectionAttempt();
  }

  // ── Mode switching ─────────────────────────────────────────────────────────

  void _setMode(TicTacToeMode mode) {
    if (_gameState.connectionStatus == TicTacToeStatus.disconnected &&
        mode == TicTacToeMode.gmVsPlayer) {
      _showConnectionRequiredSnack();
      return;
    }
    setState(() {
      _gameState = _gameState.copyWith(mode: mode, isGameActive: false, winner: null, board: List.filled(9, ''));
    });
    for (final c in _cellControllers) {
      c.reset();
    }
  }

  void _showConnectionRequiredSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
            Gap(8),
            Text('Connexion au Raspberry Pi requise pour jouer en tant que GM'),
          ],
        ),
        backgroundColor: _warningOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Game actions ───────────────────────────────────────────────────────────

  void _startGame() {
    setState(() {
      _gameState = _gameState.copyWith(
        board: List.filled(9, ''),
        currentTurn: 'X',
        winner: null,
        isGameActive: true,
      );
    });
    _winController.reset();
    for (final c in _cellControllers) {
      c.reset();
    }
  }

  void _resetGame() {
    _aiMoveTimer?.cancel();
    setState(() {
      _gameState = _gameState.copyWith(
        board: List.filled(9, ''),
        currentTurn: 'X',
        winner: null,
        isGameActive: false,
      );
    });
    _winController.reset();
    for (final c in _cellControllers) {
      c.reset();
    }
  }

  void _onGmCellTap(int index) {
    if (!_gameState.isGameActive) return;
    if (_gameState.board[index].isNotEmpty) return;
    if (_gameState.winner != null) return;

    // In GM vs Player mode, GM plays as 'O'
    if (_gameState.mode == TicTacToeMode.gmVsPlayer &&
        _gameState.currentTurn != 'O') {
      return;
    }

    _makeMove(index);
  }

  void _makeMove(int index) {
    if (_gameState.board[index].isNotEmpty) return;
    final newBoard = List<String>.from(_gameState.board);
    final symbol = _gameState.currentTurn;
    newBoard[index] = symbol;

    _cellControllers[index].forward();

    final winner = TicTacToeLogic.checkWinner(newBoard);
    final nextTurn = symbol == 'X' ? 'O' : 'X';

    setState(() {
      _gameState = _gameState.copyWith(
        board: newBoard,
        currentTurn: winner == null ? nextTurn : symbol,
        winner: winner,
        isGameActive: winner == null,
      );
    });

    if (winner != null) {
      _winController.forward();
      return;
    }

    // AI move
    if (_gameState.mode == TicTacToeMode.aiVsPlayer && nextTurn == 'O') {
      _scheduleAiMove(newBoard);
    }
  }

  void _scheduleAiMove(List<String> board) {
    _aiMoveTimer?.cancel();
    _aiMoveTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final move = TicTacToeLogic.getAiMove(board, 'O', _gameState.aiDifficulty);
      if (move != null && _gameState.isGameActive) {
        _makeMove(move);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _secondaryBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(color: Color(0xFF2D2D2D), height: 1),
          _buildConnectionStatus(),
          const Divider(color: Color(0xFF2D2D2D), height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildModeSelector(),
                const Gap(20),
                _buildBoard(),
                const Gap(20),
                _buildStatusDisplay(),
                const Gap(16),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_3x3_rounded, color: _primaryRed, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.enigmaName.toUpperCase(),
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'MODULE : TIC TAC TOE',
                  style: TextStyle(color: _grayText, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Live indicator
          if (_gameState.isGameActive)
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _primaryRed.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: _primaryRed, size: 6),
                    Gap(5),
                    Text(
                      'EN JEU',
                      style: TextStyle(color: _primaryRed, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Connection status ──────────────────────────────────────────────────────

  Widget _buildConnectionStatus() {
    final isConnected = _gameState.connectionStatus == TicTacToeStatus.connected;
    final isWaiting = _gameState.connectionStatus == TicTacToeStatus.waitingConnection;
    final isDisconnected = _gameState.connectionStatus == TicTacToeStatus.disconnected;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isConnected) {
      statusColor = _successGreen;
      statusLabel = 'RASPBERRY PI CONNECTÉ';
      statusIcon = Icons.wifi_rounded;
    } else if (isWaiting) {
      statusColor = _warningOrange;
      statusLabel = 'CONNEXION EN COURS...';
      statusIcon = Icons.wifi_find_rounded;
    } else {
      statusColor = _grayText;
      statusLabel = 'HORS LIGNE — MODE IA ACTIVÉ';
      statusIcon = Icons.wifi_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: statusColor.withValues(alpha: 0.05),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) => Icon(
              statusIcon,
              color: isWaiting
                  ? Color.lerp(_warningOrange, Colors.white, _pulseController.value * 0.3)!
                  : statusColor,
              size: 16,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          if (widget.raspberryPiIp != null)
            Text(
              widget.raspberryPiIp!,
              style: const TextStyle(color: _grayText, fontSize: 9, fontFamily: 'monospace'),
            ),
          if (isDisconnected) ...[
            const Gap(12),
            GestureDetector(
              onTap: _retryConnection,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: _grayBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(color: _grayText, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mode selector ──────────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    final isDisconnected = _gameState.connectionStatus == TicTacToeStatus.disconnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MODE DE JEU',
          style: TextStyle(color: _grayText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'GAME MASTER',
                sublabel: 'VS JOUEUR',
                icon: Icons.person_rounded,
                isSelected: _gameState.mode == TicTacToeMode.gmVsPlayer,
                isDisabled: isDisconnected,
                disabledReason: 'Connexion requise',
                color: _primaryRed,
                onTap: () => _setMode(TicTacToeMode.gmVsPlayer),
              ),
            ),
            const Gap(10),
            Expanded(
              child: _ModeButton(
                label: 'INTELLIGENCE',
                sublabel: 'ARTIFICIELLE',
                icon: Icons.smart_toy_rounded,
                isSelected: _gameState.mode == TicTacToeMode.aiVsPlayer,
                isDisabled: false,
                color: _warningOrange,
                onTap: () => _setMode(TicTacToeMode.aiVsPlayer),
                badge: isDisconnected ? 'AUTO' : null,
              ),
            ),
          ],
        ),
        if (_gameState.mode == TicTacToeMode.aiVsPlayer) ...[
          const Gap(12),
          _AiDifficultySelector(
            selected: _gameState.aiDifficulty,
            onChanged: (d) => setState(() {
              _gameState = _gameState.copyWith(aiDifficulty: d);
            }),
          ),
        ],
        if (_gameState.mode == TicTacToeMode.gmVsPlayer) ...[
          const Gap(10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primaryRed.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _primaryRed, size: 14),
                Gap(8),
                Expanded(
                  child: Text(
                    'Vous jouez O — le joueur joue X depuis le Raspberry Pi',
                    style: TextStyle(color: _grayText, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Board ──────────────────────────────────────────────────────────────────

  Widget _buildBoard() {
    final winCells = TicTacToeLogic.getWinningCells(_gameState.board);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: _primaryBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _grayBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final isWinCell = winCells.contains(index);
            final cellValue = _gameState.board[index];
            final isGmTurn = _gameState.mode == TicTacToeMode.gmVsPlayer &&
                _gameState.currentTurn == 'O' &&
                cellValue.isEmpty &&
                _gameState.isGameActive;

            return ScaleTransition(
              scale: CurvedAnimation(
                parent: _cellControllers[index],
                curve: Curves.elasticOut,
              ).drive(Tween(begin: 0.5, end: 1.0)),
              child: GestureDetector(
                onTap: isGmTurn ? () => _onGmCellTap(index) : null,
                child: AnimatedBuilder(
                  animation: _winController,
                  builder: (_, _) {
                    final isGlowing = isWinCell && _gameState.winner != null && _gameState.winner != 'draw';
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isGlowing
                            ? (cellValue == 'X' ? _primaryRed : _warningOrange).withValues(alpha: 0.15 + _winController.value * 0.1)
                            : isGmTurn
                                ? _primaryRed.withValues(alpha: 0.05)
                                : _secondaryBlack,
                        border: Border.all(
                          color: isGlowing
                              ? (cellValue == 'X' ? _primaryRed : _warningOrange).withValues(alpha: 0.6)
                              : isGmTurn
                                  ? _primaryRed.withValues(alpha: 0.3)
                                  : _grayBorder.withValues(alpha: 0.5),
                          width: isGlowing ? 2 : 1,
                        ),
                        boxShadow: isGlowing
                            ? [
                                BoxShadow(
                                  color: (cellValue == 'X' ? _primaryRed : _warningOrange).withValues(alpha: 0.3 * _winController.value),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: cellValue.isNotEmpty
                            ? _CellSymbol(symbol: cellValue)
                            : isGmTurn
                                ? Icon(Icons.add_rounded, color: _primaryRed.withValues(alpha: 0.3), size: 20)
                                : null,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Status display ─────────────────────────────────────────────────────────

  Widget _buildStatusDisplay() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!_gameState.isGameActive && _gameState.winner == null) {
      statusText = 'EN ATTENTE DE DÉMARRAGE';
      statusColor = _grayText;
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (_gameState.winner == 'draw') {
      statusText = 'MATCH NUL — ÉGALITÉ !';
      statusColor = _warningOrange;
      statusIcon = Icons.handshake_rounded;
    } else if (_gameState.winner == 'X') {
      statusText = 'LE JOUEUR GAGNE !';
      statusColor = _primaryRed;
      statusIcon = Icons.emoji_events_rounded;
    } else if (_gameState.winner == 'O') {
      final label = _gameState.mode == TicTacToeMode.gmVsPlayer ? 'LE GM GAGNE !' : "L'IA GAGNE !";
      statusText = label;
      statusColor = _warningOrange;
      statusIcon = _gameState.mode == TicTacToeMode.gmVsPlayer ? Icons.emoji_events_rounded : Icons.smart_toy_rounded;
    } else {
      final isGmTurn = _gameState.mode == TicTacToeMode.gmVsPlayer && _gameState.currentTurn == 'O';
      final isAiTurn = _gameState.mode == TicTacToeMode.aiVsPlayer && _gameState.currentTurn == 'O';

      if (isGmTurn) {
        statusText = 'VOTRE TOUR — CHOISISSEZ UNE CASE';
        statusColor = _primaryRed;
        statusIcon = Icons.ads_click_rounded;
      } else if (isAiTurn) {
        statusText = "TOUR DE L'IA...";
        statusColor = _warningOrange;
        statusIcon = Icons.psychology_rounded;
      } else {
        statusText = 'TOUR DU JOUEUR';
        statusColor = _white;
        statusIcon = Icons.person_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const Gap(10),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final hasEnded = _gameState.winner != null;
    final hasStarted = _gameState.isGameActive || hasEnded;

    return Row(
      children: [
        if (hasStarted)
          Expanded(
            child: _OutlineActionButton(
              label: 'RÉINITIALISER',
              icon: Icons.refresh_rounded,
              onPressed: _resetGame,
            ),
          ),
        if (hasStarted) const Gap(12),
        Expanded(
          flex: hasStarted ? 2 : 1,
          child: _PrimaryActionButton(
            label: hasEnded ? 'REJOUER' : (hasStarted ? 'EN COURS...' : 'DÉMARRER LA PARTIE'),
            icon: hasEnded ? Icons.replay_rounded : Icons.play_arrow_rounded,
            onPressed: (!hasStarted || hasEnded) ? _startGame : null,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _CellSymbol extends StatelessWidget {
  final String symbol;
  const _CellSymbol({required this.symbol});

  static const Color _primaryRed = Color(0xFFDC143C);
  static const Color _warningOrange = Color(0xFFFFA500);

  @override
  Widget build(BuildContext context) {
    if (symbol == 'X') {
      return Text(
        'X',
        style: TextStyle(
          color: _primaryRed,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          shadows: [Shadow(color: _primaryRed.withValues(alpha: 0.4), blurRadius: 12)],
        ),
      );
    }
    return Text(
      'O',
      style: TextStyle(
        color: _warningOrange,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
        shadows: [Shadow(color: _warningOrange.withValues(alpha: 0.4), blurRadius: 12)],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final String? disabledReason;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _ModeButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.color,
    required this.onTap,
    this.disabledReason,
    this.badge,
  });

  static const Color _primaryBlack = Color(0xFF0D0D0D);
  static const Color _secondaryBlack = Color(0xFF1A1A1A);
  static const Color _grayBorder = Color(0xFF2D2D2D);
  static const Color _grayText = Color(0xFFB8B8B8);
  static const Color _grayDisabled = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : _primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : isDisabled ? _grayBorder.withValues(alpha: 0.3) : _grayBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isDisabled ? _grayDisabled : (isSelected ? color : _grayText), size: 22),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? _grayDisabled : (isSelected ? color : _grayText),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: isDisabled ? _grayDisabled.withValues(alpha: 0.6) : (isSelected ? color.withValues(alpha: 0.7) : _grayText.withValues(alpha: 0.6)),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isDisabled && disabledReason != null) ...[
              const Gap(4),
              Text(
                disabledReason!,
                style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 7),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiDifficultySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _AiDifficultySelector({required this.selected, required this.onChanged});

  static const _levels = ['Facile', 'Moyen', 'Difficile', 'Imbattable'];

  static const Color _primaryBlack = Color(0xFF0D0D0D);
  static const Color _grayBorder = Color(0xFF2D2D2D);
  static const Color _grayText = Color(0xFFB8B8B8);
  static const Color _primaryRed = Color(0xFFDC143C);
  static const Color _successGreen = Color(0xFF28A745);
  static const Color _warningOrange = Color(0xFFFFA500);

  Color _colorFor(String level) {
    switch (level) {
      case 'Facile':
        return _successGreen;
      case 'Moyen':
        return _warningOrange;
      case 'Difficile':
        return _primaryRed;
      case 'Imbattable':
        return const Color(0xFF8B0000);
      default:
        return _grayText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "NIVEAU DE L'IA",
          style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const Gap(8),
        Row(
          children: _levels.map((level) {
            final isSelected = selected == level;
            final color = _colorFor(level);
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.12) : _primaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color.withValues(alpha: 0.7) : _grayBorder,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? color : _grayText,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({required this.label, required this.icon, this.onPressed});

  static const Color _primaryRed = Color(0xFFDC143C);
  static const Color _grayDisabled = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled ? _grayDisabled.withValues(alpha: 0.3) : _primaryRed,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDisabled
              ? []
              : [BoxShadow(color: _primaryRed.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: isDisabled ? 0.3 : 1), size: 18),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isDisabled ? 0.3 : 1),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineActionButton({required this.label, required this.icon, required this.onPressed});

  static const Color _grayBorder = Color(0xFF2D2D2D);
  static const Color _grayText = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _grayBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _grayText, size: 18),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(
                color: _grayText,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}