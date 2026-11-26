import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_party/ai/ai_engine.dart';
import 'package:uno_party/models/game_rules_config.dart';
import 'package:uno_party/models/game_state.dart';
import 'package:uno_party/models/player.dart';
import 'package:uno_party/models/uno_card.dart';
import 'package:uno_party/rules/rules_engine.dart';

void main() {
  late RulesEngine engine;

  setUp(() {
    engine = RulesEngine(random: Random(42));
  });

  List<Player> makePlayers(int count) => [
        for (int i = 0; i < count; i++)
          Player(
            id: 'p$i',
            name: 'Player $i',
            characterId: 'aria',
            isHuman: i == 0,
            aiDifficulty: i == 0 ? null : AiDifficulty.hard,
            hand: const [],
          ),
      ];

  test('Standard deck has exactly 108 cards', () {
    final deck = engine.buildStandardDeck();
    expect(deck.length, 108);
    expect(deck.where((c) => c.value == CardValue.wild).length, 4);
    expect(deck.where((c) => c.value == CardValue.wildDrawFour).length, 4);
    expect(deck.where((c) => c.value == CardValue.zero).length, 4);
  });

  test('Initial deal gives 7 cards to each player and 1 non-+4 discard', () {
    final state = engine.createInitialGame(
      mode: GameModeType.singlePlayerAi,
      players: makePlayers(4),
      rules: const GameRulesConfig(),
    );
    for (final p in state.players) {
      expect(p.hand.length, 7);
    }
    expect(state.discardPile.length, 1);
    expect(state.topDiscard.value, isNot(CardValue.wildDrawFour));
    expect(
      state.drawPile.length + state.discardPile.length + 28,
      108,
    );
  });

  test('Skip advances turn by 2 players', () {
    final p = makePlayers(3);
    p[0] = p[0].copyWith(hand: [
      const UnoCard(id: 's1', color: CardColor.red, value: CardValue.skip),
      const UnoCard(id: 'r2', color: CardColor.red, value: CardValue.two),
    ]);
    final state = GameState(
      mode: GameModeType.singlePlayerAi,
      rules: const GameRulesConfig(),
      players: p,
      drawPile: engine.buildStandardDeck(),
      discardPile: const [
        UnoCard(id: 'd0', color: CardColor.red, value: CardValue.five),
      ],
      currentPlayerIndex: 0,
      direction: 1,
      activeColor: CardColor.red,
    );

    final next = engine.playCard(
      state,
      playerIndex: 0,
      card: p[0].hand.first,
    );
    expect(next.currentPlayerIndex, 2);
  });

  test('Reverse in 2-player game acts like Skip (same player goes again)', () {
    final p = makePlayers(2);
    p[0] = p[0].copyWith(hand: [
      const UnoCard(id: 'rev', color: CardColor.blue, value: CardValue.reverse),
      const UnoCard(id: 'b1', color: CardColor.blue, value: CardValue.one),
    ]);
    final state = GameState(
      mode: GameModeType.singlePlayerAi,
      rules: const GameRulesConfig(),
      players: p,
      drawPile: engine.buildStandardDeck(),
      discardPile: const [
        UnoCard(id: 'd0', color: CardColor.blue, value: CardValue.three),
      ],
      currentPlayerIndex: 0,
      direction: 1,
      activeColor: CardColor.blue,
    );

    final next = engine.playCard(
      state,
      playerIndex: 0,
      card: p[0].hand.first,
    );
    expect(next.currentPlayerIndex, 0);
  });

  test('+4 illegal bluff challenge penalizes offender with 4 cards', () {
    final p = makePlayers(2);
    p[0] = p[0].copyWith(hand: [
      const UnoCard(
          id: 'w4', color: CardColor.wild, value: CardValue.wildDrawFour),
      // Has matching activeColor (red) -> illegal bluff!
      const UnoCard(id: 'r1', color: CardColor.red, value: CardValue.one),
      const UnoCard(id: 'g2', color: CardColor.green, value: CardValue.two),
    ]);
    p[1] = p[1].copyWith(hand: [
      const UnoCard(id: 'b1', color: CardColor.blue, value: CardValue.one),
    ]);

    final state = GameState(
      mode: GameModeType.singlePlayerAi,
      rules: const GameRulesConfig(),
      players: p,
      drawPile: engine.buildStandardDeck(),
      discardPile: const [
        UnoCard(id: 'd0', color: CardColor.red, value: CardValue.nine),
      ],
      currentPlayerIndex: 0,
      direction: 1,
      activeColor: CardColor.red,
    );

    final afterPlay = engine.playCard(
      state,
      playerIndex: 0,
      card: p[0].hand.first,
      chosenWildColor: CardColor.yellow,
    );
    expect(afterPlay.phase, TurnPhase.awaitingPlusFourChallenge);

    final afterChallenge =
        engine.resolvePlusFourChallenge(afterPlay, challenge: true);
    expect(afterChallenge.players[0].hand.length, 6); // 2 left + 4 penalty
    expect(afterChallenge.currentPlayerIndex, 1);
  });

  test('+4 legal play failed challenge penalizes challenger with 6 cards', () {
    final p = makePlayers(2);
    p[0] = p[0].copyWith(hand: [
      const UnoCard(
          id: 'w4', color: CardColor.wild, value: CardValue.wildDrawFour),
      const UnoCard(id: 'g2', color: CardColor.green, value: CardValue.two),
    ]);
    p[1] = p[1].copyWith(hand: [
      const UnoCard(id: 'b1', color: CardColor.blue, value: CardValue.one),
    ]);

    final state = GameState(
      mode: GameModeType.singlePlayerAi,
      rules: const GameRulesConfig(),
      players: p,
      drawPile: engine.buildStandardDeck(),
      discardPile: const [
        UnoCard(id: 'd0', color: CardColor.red, value: CardValue.nine),
      ],
      currentPlayerIndex: 0,
      direction: 1,
      activeColor: CardColor.red,
    );

    final afterPlay = engine.playCard(
      state,
      playerIndex: 0,
      card: p[0].hand.first,
      chosenWildColor: CardColor.blue,
    );
    final afterChallenge =
        engine.resolvePlusFourChallenge(afterPlay, challenge: true);
    expect(afterChallenge.players[1].hand.length, 7); // 1 + 6 penalty
  });

  test('UNO penalty adds 2 cards when player has 1 card and did not say UNO', () {
    final p = makePlayers(2);
    p[0] = p[0].copyWith(
      hand: [const UnoCard(id: 'r1', color: CardColor.red, value: CardValue.one)],
      saidUno: false,
    );
    final state = GameState(
      mode: GameModeType.singlePlayerAi,
      rules: const GameRulesConfig(),
      players: p,
      drawPile: engine.buildStandardDeck(),
      discardPile: const [
        UnoCard(id: 'd0', color: CardColor.red, value: CardValue.nine),
      ],
      currentPlayerIndex: 1,
      direction: 1,
      activeColor: CardColor.red,
    );

    final caught = engine.catchUnoPenalty(state, 0);
    expect(caught.players[0].hand.length, 3);
  });

  test('Optional Stacking allows +2 on +2', () {
    final p = makePlayers(2);
    p[0] = p[0].copyWith(hand: [
      const UnoCard(id: 'p2a', color: CardColor.red, value: CardValue.drawTwo),
      const UnoCard(id: 'r1', color: CardColor.red, value: CardValue.one),
    ]);
    p[1] = p[1].copyWith(hand: [
      const UnoCard(id: 'p2b', color: CardColor.blue, value: CardValue.drawTwo),
      const UnoCard(id: 'b1', color: CardColor.blue, value: CardValue.one),
    ]);

    final state = GameState(
      mode: GameModeType.singlePlayerAi,
      rules: const GameRulesConfig(allowStacking: true),
      players: p,
      drawPile: engine.buildStandardDeck(),
      discardPile: const [
        UnoCard(id: 'd0', color: CardColor.red, value: CardValue.five),
      ],
      currentPlayerIndex: 0,
      direction: 1,
      activeColor: CardColor.red,
    );

    final s1 = engine.playCard(state, playerIndex: 0, card: p[0].hand.first);
    expect(s1.pendingDrawCount, 2);
    expect(engine.isCardPlayable(s1, p[1].hand.first), isTrue);
    expect(engine.isCardPlayable(s1, p[1].hand.last), isFalse);
  });

  test('AI engine only accesses public information and its own hand', () {
    final ai = AiEngine(rulesEngine: engine, random: Random(1));
    final state = engine.createInitialGame(
      mode: GameModeType.singlePlayerAi,
      players: makePlayers(3),
      rules: const GameRulesConfig(),
    );
    final view = AiPublicView.fromState(state, 1);
    expect(view.myHand.length, 7);
    expect(view.opponentHandCounts, [7, 7]);
    final decision = ai.decideMove(state, 1);
    expect(decision.cardToPlay != null || decision.shouldDraw, isTrue);
  });
}
