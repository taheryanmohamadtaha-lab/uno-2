import 'game_rules_config.dart';
import 'player.dart';
import 'uno_card.dart';

enum GameModeType { singlePlayerAi, localMultiplayer, tournament }

enum TurnPhase {
  playing,
  awaitingWildColor,
  awaitingDrawDecision, // Player drew 1 card and can play ONLY that drawn card or pass
  awaitingPlusFourChallenge,
  awaitingPassDevice, // Local multiplayer privacy screen
  finished,
}

class WildDrawFourChallenge {
  final int offenderIndex;
  final int challengerIndex;
  final bool wasIllegalBluff;

  const WildDrawFourChallenge({
    required this.offenderIndex,
    required this.challengerIndex,
    required this.wasIllegalBluff,
  });

  Map<String, dynamic> toJson() => {
        'offenderIndex': offenderIndex,
        'challengerIndex': challengerIndex,
        'wasIllegalBluff': wasIllegalBluff,
      };

  factory WildDrawFourChallenge.fromJson(Map<String, dynamic> json) =>
      WildDrawFourChallenge(
        offenderIndex: json['offenderIndex'] as int,
        challengerIndex: json['challengerIndex'] as int,
        wasIllegalBluff: json['wasIllegalBluff'] as bool,
      );
}

class GameState {
  final GameModeType mode;
  final GameRulesConfig rules;
  final List<Player> players;
  final List<UnoCard> drawPile;
  final List<UnoCard> discardPile;
  final int currentPlayerIndex;
  final int direction; // 1 = clockwise, -1 = counter-clockwise
  final CardColor activeColor;
  final int pendingDrawCount;
  final CardValue? pendingStackType;
  final String? drawnCardIdThisTurn;
  final TurnPhase phase;
  final WildDrawFourChallenge? pendingChallenge;
  final String statusMessage;
  final int? winnerIndex;

  const GameState({
    required this.mode,
    required this.rules,
    required this.players,
    required this.drawPile,
    required this.discardPile,
    required this.currentPlayerIndex,
    required this.direction,
    required this.activeColor,
    this.pendingDrawCount = 0,
    this.pendingStackType,
    this.drawnCardIdThisTurn,
    this.phase = TurnPhase.playing,
    this.pendingChallenge,
    this.statusMessage = '',
    this.winnerIndex,
  });

  UnoCard get topDiscard => discardPile.last;
  Player get currentPlayer => players[currentPlayerIndex];

  GameState copyWith({
    List<Player>? players,
    List<UnoCard>? drawPile,
    List<UnoCard>? discardPile,
    int? currentPlayerIndex,
    int? direction,
    CardColor? activeColor,
    int? pendingDrawCount,
    CardValue? pendingStackType,
    bool clearPendingStackType = false,
    String? drawnCardIdThisTurn,
    bool clearDrawnCardId = false,
    TurnPhase? phase,
    WildDrawFourChallenge? pendingChallenge,
    bool clearPendingChallenge = false,
    String? statusMessage,
    int? winnerIndex,
  }) {
    return GameState(
      mode: mode,
      rules: rules,
      players: players ?? this.players,
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      direction: direction ?? this.direction,
      activeColor: activeColor ?? this.activeColor,
      pendingDrawCount: pendingDrawCount ?? this.pendingDrawCount,
      pendingStackType: clearPendingStackType
          ? null
          : (pendingStackType ?? this.pendingStackType),
      drawnCardIdThisTurn: clearDrawnCardId
          ? null
          : (drawnCardIdThisTurn ?? this.drawnCardIdThisTurn),
      phase: phase ?? this.phase,
      pendingChallenge: clearPendingChallenge
          ? null
          : (pendingChallenge ?? this.pendingChallenge),
      statusMessage: statusMessage ?? this.statusMessage,
      winnerIndex: winnerIndex ?? this.winnerIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'rules': rules.toJson(),
        'players': players.map((p) => p.toJson()).toList(),
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'direction': direction,
        'activeColor': activeColor.name,
        'pendingDrawCount': pendingDrawCount,
        'pendingStackType': pendingStackType?.name,
        'drawnCardIdThisTurn': drawnCardIdThisTurn,
        'phase': phase.name,
        'pendingChallenge': pendingChallenge?.toJson(),
        'statusMessage': statusMessage,
        'winnerIndex': winnerIndex,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        mode: GameModeType.values.byName(json['mode'] as String),
        rules: GameRulesConfig.fromJson(json['rules'] as Map<String, dynamic>),
        players: (json['players'] as List)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        drawPile: (json['drawPile'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        discardPile: (json['discardPile'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPlayerIndex: json['currentPlayerIndex'] as int,
        direction: json['direction'] as int,
        activeColor: CardColor.values.byName(json['activeColor'] as String),
        pendingDrawCount: json['pendingDrawCount'] as int? ?? 0,
        pendingStackType: json['pendingStackType'] != null
            ? CardValue.values.byName(json['pendingStackType'] as String)
            : null,
        drawnCardIdThisTurn: json['drawnCardIdThisTurn'] as String?,
        phase: TurnPhase.values.byName(json['phase'] as String),
        pendingChallenge: json['pendingChallenge'] != null
            ? WildDrawFourChallenge.fromJson(
                json['pendingChallenge'] as Map<String, dynamic>,
              )
            : null,
        statusMessage: json['statusMessage'] as String? ?? '',
        winnerIndex: json['winnerIndex'] as int?,
      );
}
