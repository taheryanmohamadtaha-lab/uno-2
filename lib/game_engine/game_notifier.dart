import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_engine.dart';
import '../models/character.dart';
import '../models/game_rules_config.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/uno_card.dart';
import '../rules/rules_engine.dart';
import '../services/sound_service.dart';
import '../settings/app_settings.dart';
import '../statistics/stats_models.dart';
import '../storage/local_storage_service.dart';
import '../tournament/tournament_notifier.dart';

class GameNotifier extends StateNotifier<GameState?> {
  final RulesEngine rulesEngine;
  final AiEngine aiEngine;
  final LocalStorageService storage;
  final Ref ref;
  Timer? _aiTimer;
  UnoCard? _pendingWildCard;

  GameNotifier({
    required this.rulesEngine,
    required this.aiEngine,
    required this.storage,
    required this.ref,
  }) : super(null);

  SoundService get _sound {
    final s = ref.read(settingsProvider);
    return SoundService(
      soundEnabled: s.soundEnabled,
      vibrationEnabled: s.vibrationEnabled,
    );
  }

  Future<bool> hasSavedGame() async {
    final saved = await storage.loadUnfinishedGame();
    return saved != null && saved.phase != TurnPhase.finished;
  }

  Future<void> resumeSavedGame() async {
    final saved = await storage.loadUnfinishedGame();
    if (saved != null) {
      state = saved;
      _scheduleAiIfNeeded();
    }
  }

  void startAiGame({
    required int opponentCount,
    required AiDifficulty difficulty,
    required GameRulesConfig rules,
    required String playerCharacterId,
    bool isTournament = false,
  }) {
    final userChar = characterById(playerCharacterId);
    final aiChars = kGameCharacters
        .where((c) => c.id != playerCharacterId)
        .take(opponentCount.clamp(1, 3))
        .toList();

    final players = <Player>[
      Player(
        id: 'p_human',
        name: userChar.name(ref.read(settingsProvider).language),
        characterId: userChar.id,
        isHuman: true,
        hand: const [],
      ),
      for (int i = 0; i < aiChars.length; i++)
        Player(
          id: 'p_ai_$i',
          name: aiChars[i].name(ref.read(settingsProvider).language),
          characterId: aiChars[i].id,
          isHuman: false,
          aiDifficulty: difficulty,
          hand: const [],
        ),
    ];

    state = rulesEngine.createInitialGame(
      mode: isTournament ? GameModeType.tournament : GameModeType.singlePlayerAi,
      players: players,
      rules: rules,
      initialMessage: 'بازی آغاز شد!',
    );
    _persistGame();
    _scheduleAiIfNeeded();
  }

  void startLocalMultiplayer({
    required List<({String name, String characterId})> humanPlayers,
    required GameRulesConfig rules,
  }) {
    final players = <Player>[
      for (int i = 0; i < humanPlayers.length; i++)
        Player(
          id: 'p_local_$i',
          name: humanPlayers[i].name,
          characterId: humanPlayers[i].characterId,
          isHuman: true,
          hand: const [],
        ),
    ];

    state = rulesEngine.createInitialGame(
      mode: GameModeType.localMultiplayer,
      players: players,
      rules: rules,
      initialMessage: 'چندنفره محلی آماده است!',
    );
    _persistGame();
  }

  void confirmPassDevice() {
    final s = state;
    if (s == null || s.phase != TurnPhase.awaitingPassDevice) return;
    state = s.copyWith(phase: TurnPhase.playing);
    _persistGame();
  }

  void playHumanCard(UnoCard card) {
    final s = state;
    if (s == null || !s.currentPlayer.isHuman) return;
    if (!rulesEngine.isCardPlayable(s, card)) return;

    if (card.isWild) {
      _pendingWildCard = card;
      state = s.copyWith(phase: TurnPhase.awaitingWildColor);
      return;
    }

    if (card.isAction) {
      _sound.playSpecialCard();
    } else {
      _sound.playCard();
    }

    state = rulesEngine.playCard(
      s,
      playerIndex: s.currentPlayerIndex,
      card: card,
    );
    _afterStateChange();
  }

  void selectWildColor(CardColor color) {
    final s = state;
    final card = _pendingWildCard;
    if (s == null || card == null || s.phase != TurnPhase.awaitingWildColor) {
      return;
    }
    _pendingWildCard = null;
    _sound.playSpecialCard();

    state = rulesEngine.playCard(
      s,
      playerIndex: s.currentPlayerIndex,
      card: card,
      chosenWildColor: color,
    );
    _afterStateChange();
  }

  void drawCard() {
    final s = state;
    if (s == null || !s.currentPlayer.isHuman) return;
    _sound.playDraw();
    state = rulesEngine.drawAction(s, s.currentPlayerIndex);
    _afterStateChange();
  }

  void passAfterDraw() {
    final s = state;
    if (s == null || !s.currentPlayer.isHuman) return;
    state = rulesEngine.passAfterDraw(s, s.currentPlayerIndex);
    _afterStateChange();
  }

  void callUno() {
    final s = state;
    if (s == null) return;
    _sound.playUno();
    state = rulesEngine.callUno(s, s.currentPlayerIndex);
    _persistGame();
  }

  void catchUno(int targetPlayerIndex) {
    final s = state;
    if (s == null) return;
    _sound.playPenalty();
    state = rulesEngine.catchUnoPenalty(s, targetPlayerIndex);
    _persistGame();
  }

  void resolvePlusFourChallenge(bool challenge) {
    final s = state;
    if (s == null || s.phase != TurnPhase.awaitingPlusFourChallenge) return;
    if (challenge) {
      _sound.playPenalty();
    } else {
      _sound.playDraw();
    }
    state = rulesEngine.resolvePlusFourChallenge(s, challenge: challenge);
    _afterStateChange();
  }

  void _afterStateChange() {
    final s = state;
    if (s == null) return;
    if (s.phase == TurnPhase.finished && s.winnerIndex != null) {
      _aiTimer?.cancel();
      _sound.playWin();
      storage.clearUnfinishedGame();

      final winner = s.players[s.winnerIndex!];
      final points = s.players
          .where((p) => p.id != winner.id)
          .expand((p) => p.hand)
          .fold<int>(0, (sum, c) => sum + c.points);

      final humanWon = winner.isHuman &&
          (s.mode != GameModeType.localMultiplayer || s.winnerIndex == 0);
      ref.read(statsProvider.notifier).recordMatch(
            mode: s.mode.name,
            won: humanWon,
            score: points,
          );
      if (s.mode == GameModeType.tournament) {
        ref
            .read(tournamentProvider.notifier)
            .recordStageResult(won: winner.isHuman, points: points);
      }
      return;
    }

    _persistGame();
    _scheduleAiIfNeeded();
  }

  void _scheduleAiIfNeeded() {
    _aiTimer?.cancel();
    final s = state;
    if (s == null || s.phase == TurnPhase.finished) return;
    if (s.currentPlayer.isHuman) return;

    _aiTimer = Timer(const Duration(milliseconds: 850), _executeAiStep);
  }

  void _executeAiStep() {
    final s = state;
    if (s == null || s.currentPlayer.isHuman || s.phase == TurnPhase.finished) {
      return;
    }

    if (s.phase == TurnPhase.awaitingPlusFourChallenge) {
      final shouldChallenge =
          aiEngine.decidePlusFourChallenge(s, s.currentPlayerIndex);
      state = rulesEngine.resolvePlusFourChallenge(s, challenge: shouldChallenge);
      _afterStateChange();
      return;
    }

    final decision = aiEngine.decideMove(s, s.currentPlayerIndex);
    var nextState = s;

    if (decision.shouldCallUno) {
      nextState = rulesEngine.callUno(nextState, s.currentPlayerIndex);
    }

    if (decision.cardToPlay != null) {
      _sound.playCard();
      nextState = rulesEngine.playCard(
        nextState,
        playerIndex: s.currentPlayerIndex,
        card: decision.cardToPlay!,
        chosenWildColor: decision.wildColor,
      );
    } else if (s.phase == TurnPhase.awaitingDrawDecision) {
      nextState = rulesEngine.passAfterDraw(nextState, s.currentPlayerIndex);
    } else {
      _sound.playDraw();
      nextState = rulesEngine.drawAction(nextState, s.currentPlayerIndex);
    }

    state = nextState;
    _afterStateChange();
  }

  void _persistGame() {
    final s = state;
    if (s != null && s.phase != TurnPhase.finished) {
      storage.saveUnfinishedGame(s);
    }
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }
}

final rulesEngineProvider = Provider((ref) => RulesEngine());
final aiEngineProvider =
    Provider((ref) => AiEngine(rulesEngine: ref.watch(rulesEngineProvider)));

final gameProvider = StateNotifierProvider<GameNotifier, GameState?>(
  (ref) => GameNotifier(
    rulesEngine: ref.watch(rulesEngineProvider),
    aiEngine: ref.watch(aiEngineProvider),
    storage: ref.watch(storageServiceProvider),
    ref: ref,
  ),
);
