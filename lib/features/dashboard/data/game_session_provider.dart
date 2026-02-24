import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Duration of a game session (60 minutes)
const kSessionDuration = Duration(minutes: 60);

class GameSessionState {
  final bool isRunning;
  final Duration remaining;
  final String? scenarioId;

  const GameSessionState({
    this.isRunning = false,
    this.remaining = kSessionDuration,
    this.scenarioId,
  });

  bool get isFinished => remaining <= Duration.zero;

  GameSessionState copyWith({
    bool? isRunning,
    Duration? remaining,
    String? scenarioId,
  }) {
    return GameSessionState(
      isRunning: isRunning ?? this.isRunning,
      remaining: remaining ?? this.remaining,
      scenarioId: scenarioId ?? this.scenarioId,
    );
  }
}

class GameSessionNotifier extends Notifier<GameSessionState> {
  final _supabase = supa.Supabase.instance.client;
  Timer? _timer;

  @override
  GameSessionState build() => const GameSessionState();

  void startSession(String scenarioId) {
    if (state.isRunning) return;

    _updateScenarioStatus(scenarioId, true);

    state = GameSessionState(
      isRunning: true,
      remaining: kSessionDuration,
      scenarioId: scenarioId,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newRemaining = state.remaining - const Duration(seconds: 1);
      if (newRemaining <= Duration.zero) {
        resetSession();
      } else {
        state = state.copyWith(remaining: newRemaining);
      }
    });
  }

  void resetSession() {
    _timer?.cancel();
    _timer = null;

    final prevScenarioId = state.scenarioId;
    state = const GameSessionState();

    if (prevScenarioId != null) {
      _updateScenarioStatus(prevScenarioId, false);
    }
  }

  Future<void> _updateScenarioStatus(String scenarioId, bool isActive) async {
    try {
      await _supabase
          .from('scenarios')
          .update({'is_active': isActive})
          .eq('id', scenarioId);
    } catch (e) {
      // fail silently — session still runs locally
    }
  }
}

final gameSessionProvider = NotifierProvider<GameSessionNotifier, GameSessionState>(
  () => GameSessionNotifier(),
);
