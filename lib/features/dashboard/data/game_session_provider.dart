import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Duration of a game session (60 minutes)
const kSessionDuration = Duration(minutes: 60);

class GameSessionState {
  final bool isRunning;
  final Duration remaining;
  final String? scenarioId;
  final String? lastScenarioId;
  final bool needsReport;

  const GameSessionState({
    this.isRunning = false,
    this.remaining = kSessionDuration,
    this.scenarioId,
    this.lastScenarioId,
    this.needsReport = false,
  });

  bool get isFinished => remaining <= Duration.zero;

  GameSessionState copyWith({
    bool? isRunning,
    Duration? remaining,
    String? scenarioId,
    String? lastScenarioId,
    bool? needsReport,
  }) {
    return GameSessionState(
      isRunning: isRunning ?? this.isRunning,
      remaining: remaining ?? this.remaining,
      scenarioId: scenarioId ?? this.scenarioId,
      lastScenarioId: lastScenarioId ?? this.lastScenarioId,
      needsReport: needsReport ?? this.needsReport,
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
        resetSession(automatic: true);
      } else {
        state = state.copyWith(remaining: newRemaining);
      }
    });
  }

  void resetSession({bool automatic = false}) {
    _timer?.cancel();
    _timer = null;

    final prevScenarioId = state.scenarioId;
    state = GameSessionState(
      lastScenarioId: prevScenarioId,
      needsReport: true, // Always prompt for report after session stops/ends
    );

    if (prevScenarioId != null) {
      _updateScenarioStatus(prevScenarioId, false);
    }
  }

  void markReportAsHandled() {
    state = state.copyWith(needsReport: false);
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
