import 'dart:math';

import '../models/game_rules_config.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/uno_card.dart';

class RulesEngine {
  final Random _random;

  RulesEngine({Random? random}) : _random = random ?? Random();

  /// Builds the official 108-card UNO deck.
  List<UnoCard> buildStandardDeck() {
    final List<UnoCard> deck = [];
    int seq = 0;

    for (final color in [
      CardColor.red,
      CardColor.blue,
      CardColor.green,
      CardColor.yellow,
    ]) {
      deck.add(UnoCard(id: 'c_${seq++}', color: color, value: CardValue.zero));

      for (final val in [
        CardValue.one,
        CardValue.two,
        CardValue.three,
        CardValue.four,
        CardValue.five,
        CardValue.six,
        CardValue.seven,
        CardValue.eight,
        CardValue.nine,
        CardValue.skip,
        CardValue.reverse,
        CardValue.drawTwo,
      ]) {
        deck.add(UnoCard(id: 'c_${seq++}', color: color, value: val));
        deck.add(UnoCard(id: 'c_${seq++}', color: color, value: val));
      }
    }

    for (int i = 0; i < 4; i++) {
      deck.add(UnoCard(
        id: 'c_${seq++}',
        color: CardColor.wild,
        value: CardValue.wild,
      ));
      deck.add(UnoCard(
        id: 'c_${seq++}',
        color: CardColor.wild,
        value: CardValue.wildDrawFour,
      ));
    }

    return deck;
  }

  GameState createInitialGame({
    required GameModeType mode,
    required List<Player> players,
    required GameRulesConfig rules,
    String initialMessage = '',
  }) {
    final deck = buildStandardDeck()..shuffle(_random);
    final handSize = rules.initialHandSize.clamp(2, 10);

    final updatedPlayers = <Player>[];
    for (final p in players) {
      final hand = deck.sublist(0, handSize);
      deck.removeRange(0, handSize);
      updatedPlayers.add(p.copyWith(hand: hand, saidUno: false));
    }

    // Official rule: first discard cannot be Wild Draw Four (+4)
    UnoCard firstDiscard = deck.removeAt(0);
    while (firstDiscard.value == CardValue.wildDrawFour) {
      deck.add(firstDiscard);
      deck.shuffle(_random);
      firstDiscard = deck.removeAt(0);
    }

    final initialColor = firstDiscard.color == CardColor.wild
        ? CardColor.red
        : firstDiscard.color;

    final startPhase = (mode == GameModeType.localMultiplayer &&
            updatedPlayers.first.isHuman)
        ? TurnPhase.awaitingPassDevice
        : TurnPhase.playing;

    return GameState(
      mode: mode,
      rules: rules,
      players: updatedPlayers,
      drawPile: deck,
      discardPile: [firstDiscard],
      currentPlayerIndex: 0,
      direction: 1,
      activeColor: initialColor,
      phase: startPhase,
      statusMessage: initialMessage,
    );
  }

  int nextPlayerIndex(GameState state, {int steps = 1}) {
    final n = state.players.length;
    return ((state.currentPlayerIndex + state.direction * steps) % n + n) % n;
  }

  bool hasColorInHand(List<UnoCard> hand, CardColor color) {
    return hand.any((c) => c.color == color);
  }

  bool isCardPlayable(GameState state, UnoCard card) {
    if (state.phase == TurnPhase.finished) return false;

    if (state.phase == TurnPhase.awaitingDrawDecision) {
      if (card.id != state.drawnCardIdThisTurn) return false;
    }

    if (state.pendingDrawCount > 0) {
      if (!state.rules.allowStacking) return false;
      if (state.pendingStackType == CardValue.drawTwo) {
        return card.value == CardValue.drawTwo ||
            card.value == CardValue.wildDrawFour;
      }
      if (state.pendingStackType == CardValue.wildDrawFour) {
        return card.value == CardValue.wildDrawFour;
      }
      return false;
    }

    if (card.isWild) return true;
    if (card.color == state.activeColor) return true;
    if (card.value == state.topDiscard.value) return true;
    return false;
  }

  /// Draws [count] cards safely, reshuffling discard pile if needed.
  ({List<UnoCard> drawn, List<UnoCard> drawPile, List<UnoCard> discardPile})
      drawCardsFromDeck(
    List<UnoCard> drawPile,
    List<UnoCard> discardPile,
    int count,
  ) {
    final mutableDraw = List<UnoCard>.from(drawPile);
    final mutableDiscard = List<UnoCard>.from(discardPile);
    final drawn = <UnoCard>[];

    for (int i = 0; i < count; i++) {
      if (mutableDraw.isEmpty) {
        if (mutableDiscard.length <= 1) break;
        final top = mutableDiscard.removeLast();
        mutableDraw.addAll(mutableDiscard);
        mutableDiscard
          ..clear()
          ..add(top);
        mutableDraw.shuffle(_random);
      }
      if (mutableDraw.isNotEmpty) {
        drawn.add(mutableDraw.removeAt(0));
      }
    }

    return (
      drawn: drawn,
      drawPile: mutableDraw,
      discardPile: mutableDiscard,
    );
  }

  GameState playCard(
    GameState state, {
    required int playerIndex,
    required UnoCard card,
    CardColor? chosenWildColor,
  }) {
    if (playerIndex != state.currentPlayerIndex) {
      return state;
    }
    if (!isCardPlayable(state, card)) {
      return state;
    }

    final current = state.players[playerIndex];
    final previousActiveColor = state.activeColor;
    final wasIllegalPlusFour = card.value == CardValue.wildDrawFour &&
        hasColorInHand(
          current.hand.where((c) => c.id != card.id).toList(),
          previousActiveColor,
        );

    final newHand = current.hand.where((c) => c.id != card.id).toList();
    final updatedPlayers = List<Player>.from(state.players);
    updatedPlayers[playerIndex] = current.copyWith(
      hand: newHand,
      saidUno: newHand.length == 1 ? current.saidUno : false,
    );

    final newDiscard = List<UnoCard>.from(state.discardPile)..add(card);

    // Check immediate win
    if (newHand.isEmpty) {
      return state.copyWith(
        players: updatedPlayers,
        discardPile: newDiscard,
        activeColor: card.isWild ? (chosenWildColor ?? state.activeColor) : card.color,
        clearDrawnCardId: true,
        phase: TurnPhase.finished,
        winnerIndex: playerIndex,
        statusMessage: '${current.name} برنده بازی شد!',
      );
    }

    // Optional 7-0 rule
    if (state.rules.sevenZeroRule) {
      if (card.value == CardValue.seven && updatedPlayers.length >= 2) {
        final targetIdx = nextPlayerIndex(state, steps: 1);
        final myHand = updatedPlayers[playerIndex].hand;
        final theirHand = updatedPlayers[targetIdx].hand;
        updatedPlayers[playerIndex] =
            updatedPlayers[playerIndex].copyWith(hand: theirHand);
        updatedPlayers[targetIdx] =
            updatedPlayers[targetIdx].copyWith(hand: myHand);
      } else if (card.value == CardValue.zero && updatedPlayers.length >= 2) {
        final n = updatedPlayers.length;
        final oldHands = updatedPlayers.map((p) => p.hand).toList();
        for (int i = 0; i < n; i++) {
          final fromIdx = ((i - state.direction) % n + n) % n;
          updatedPlayers[i] =
              updatedPlayers[i].copyWith(hand: oldHands[fromIdx]);
        }
      }
    }

    CardColor nextColor = card.isWild
        ? (chosenWildColor ?? CardColor.red)
        : card.color;

    int nextDirection = state.direction;
    int steps = 1;
    int nextPendingDraw = state.pendingDrawCount;
    CardValue? nextStackType = state.pendingStackType;
    TurnPhase nextPhase = TurnPhase.playing;
    WildDrawFourChallenge? nextChallenge;

    if (card.value == CardValue.reverse) {
      if (updatedPlayers.length == 2) {
        steps = 2; // In 2-player UNO, Reverse acts as Skip
      } else {
        nextDirection = -state.direction;
      }
    } else if (card.value == CardValue.skip) {
      steps = 2;
    } else if (card.value == CardValue.drawTwo) {
      if (state.rules.allowStacking) {
        nextPendingDraw += 2;
        nextStackType = CardValue.drawTwo;
        steps = 1;
      } else {
        final victimIdx =
            ((playerIndex + nextDirection) % updatedPlayers.length +
                    updatedPlayers.length) %
                updatedPlayers.length;
        final res = drawCardsFromDeck(state.drawPile, newDiscard, 2);
        updatedPlayers[victimIdx] = updatedPlayers[victimIdx].copyWith(
          hand: [...updatedPlayers[victimIdx].hand, ...res.drawn],
          saidUno: false,
        );
        return _advanceTurn(
          state.copyWith(
            players: updatedPlayers,
            drawPile: res.drawPile,
            discardPile: res.discardPile,
            direction: nextDirection,
            activeColor: nextColor,
            clearDrawnCardId: true,
            statusMessage: '${updatedPlayers[victimIdx].name} ۲ کارت کشید!',
          ),
          steps: 2,
        );
      }
    } else if (card.value == CardValue.wildDrawFour) {
      if (state.rules.allowStacking) {
        nextPendingDraw += 4;
        nextStackType = CardValue.wildDrawFour;
        steps = 1;
      } else {
        final challengerIdx =
            ((playerIndex + nextDirection) % updatedPlayers.length +
                    updatedPlayers.length) %
                updatedPlayers.length;
        nextPhase = TurnPhase.awaitingPlusFourChallenge;
        nextChallenge = WildDrawFourChallenge(
          offenderIndex: playerIndex,
          challengerIndex: challengerIdx,
          wasIllegalBluff: wasIllegalPlusFour,
        );
        return state.copyWith(
          players: updatedPlayers,
          discardPile: newDiscard,
          currentPlayerIndex: challengerIdx,
          direction: nextDirection,
          activeColor: nextColor,
          clearDrawnCardId: true,
          phase: nextPhase,
          pendingChallenge: nextChallenge,
          statusMessage:
              '${current.name} کارت +4 بازی کرد! آیا اعتراض می‌کنید؟',
        );
      }
    }

    return _advanceTurn(
      state.copyWith(
        players: updatedPlayers,
        discardPile: newDiscard,
        direction: nextDirection,
        activeColor: nextColor,
        pendingDrawCount: nextPendingDraw,
        pendingStackType: nextStackType,
        clearPendingStackType: nextStackType == null,
        clearDrawnCardId: true,
        phase: nextPhase,
        statusMessage: '${current.name} کارت ${card.displayLabel} را بازی کرد.',
      ),
      steps: steps,
    );
  }

  GameState resolvePlusFourChallenge(
    GameState state, {
    required bool challenge,
  }) {
    final ch = state.pendingChallenge;
    if (ch == null) return state;

    final updatedPlayers = List<Player>.from(state.players);
    if (!challenge) {
      // Accept +4: challenger draws 4 and loses turn
      final res = drawCardsFromDeck(state.drawPile, state.discardPile, 4);
      updatedPlayers[ch.challengerIndex] =
          updatedPlayers[ch.challengerIndex].copyWith(
        hand: [...updatedPlayers[ch.challengerIndex].hand, ...res.drawn],
        saidUno: false,
      );
      return _advanceTurn(
        state.copyWith(
          players: updatedPlayers,
          drawPile: res.drawPile,
          discardPile: res.discardPile,
          clearPendingChallenge: true,
          statusMessage:
              '${updatedPlayers[ch.challengerIndex].name} ۴ کارت کشید.',
        ),
        steps: 1,
      );
    }

    if (ch.wasIllegalBluff) {
      // Challenge succeeded: offender draws 4, challenger keeps turn
      final res = drawCardsFromDeck(state.drawPile, state.discardPile, 4);
      updatedPlayers[ch.offenderIndex] =
          updatedPlayers[ch.offenderIndex].copyWith(
        hand: [...updatedPlayers[ch.offenderIndex].hand, ...res.drawn],
        saidUno: false,
      );
      return state.copyWith(
        players: updatedPlayers,
        drawPile: res.drawPile,
        discardPile: res.discardPile,
        clearPendingChallenge: true,
        phase: state.mode == GameModeType.localMultiplayer &&
                updatedPlayers[ch.challengerIndex].isHuman
            ? TurnPhase.awaitingPassDevice
            : TurnPhase.playing,
        statusMessage:
            'اعتراض موفق! ${updatedPlayers[ch.offenderIndex].name} ۴ کارت جریمه شد.',
      );
    } else {
      // Challenge failed: challenger draws 6 and loses turn
      final res = drawCardsFromDeck(state.drawPile, state.discardPile, 6);
      updatedPlayers[ch.challengerIndex] =
          updatedPlayers[ch.challengerIndex].copyWith(
        hand: [...updatedPlayers[ch.challengerIndex].hand, ...res.drawn],
        saidUno: false,
      );
      return _advanceTurn(
        state.copyWith(
          players: updatedPlayers,
          drawPile: res.drawPile,
          discardPile: res.discardPile,
          clearPendingChallenge: true,
          statusMessage:
              'اعتراض ناموفق! ${updatedPlayers[ch.challengerIndex].name} ۶ کارت جریمه شد.',
        ),
        steps: 1,
      );
    }
  }

  GameState drawAction(GameState state, int playerIndex) {
    if (playerIndex != state.currentPlayerIndex) return state;

    final updatedPlayers = List<Player>.from(state.players);
    final player = updatedPlayers[playerIndex];

    // If accepting stacked draw penalty
    if (state.pendingDrawCount > 0) {
      final res = drawCardsFromDeck(
        state.drawPile,
        state.discardPile,
        state.pendingDrawCount,
      );
      updatedPlayers[playerIndex] = player.copyWith(
        hand: [...player.hand, ...res.drawn],
        saidUno: false,
      );
      return _advanceTurn(
        state.copyWith(
          players: updatedPlayers,
          drawPile: res.drawPile,
          discardPile: res.discardPile,
          pendingDrawCount: 0,
          clearPendingStackType: true,
          statusMessage:
              '${player.name} ${state.pendingDrawCount} کارت جریمه کشید.',
        ),
        steps: 1,
      );
    }

    if (state.rules.drawUntilPlayable) {
      var curDraw = List<UnoCard>.from(state.drawPile);
      var curDiscard = List<UnoCard>.from(state.discardPile);
      final drawnList = <UnoCard>[];
      UnoCard? playable;

      for (int guard = 0; guard < 20; guard++) {
        final res = drawCardsFromDeck(curDraw, curDiscard, 1);
        curDraw = res.drawPile;
        curDiscard = res.discardPile;
        if (res.drawn.isEmpty) break;
        final c = res.drawn.first;
        drawnList.add(c);
        if (isCardPlayable(state, c)) {
          playable = c;
          break;
        }
      }

      updatedPlayers[playerIndex] = player.copyWith(
        hand: [...player.hand, ...drawnList],
        saidUno: false,
      );

      if (playable != null) {
        return state.copyWith(
          players: updatedPlayers,
          drawPile: curDraw,
          discardPile: curDiscard,
          drawnCardIdThisTurn: playable.id,
          phase: TurnPhase.awaitingDrawDecision,
          statusMessage:
              '${player.name} ${drawnList.length} کارت کشید و کارت مجاز پیدا شد.',
        );
      }
      return _advanceTurn(
        state.copyWith(
          players: updatedPlayers,
          drawPile: curDraw,
          discardPile: curDiscard,
          statusMessage: '${player.name} کارتی برای بازی نداشت.',
        ),
        steps: 1,
      );
    }

    // Standard Draw 1 Rule
    final res = drawCardsFromDeck(state.drawPile, state.discardPile, 1);
    if (res.drawn.isEmpty) {
      return _advanceTurn(state, steps: 1);
    }
    final drawnCard = res.drawn.first;
    updatedPlayers[playerIndex] = player.copyWith(
      hand: [...player.hand, drawnCard],
      saidUno: false,
    );

    if (isCardPlayable(state, drawnCard)) {
      return state.copyWith(
        players: updatedPlayers,
        drawPile: res.drawPile,
        discardPile: res.discardPile,
        drawnCardIdThisTurn: drawnCard.id,
        phase: TurnPhase.awaitingDrawDecision,
        statusMessage:
            '${player.name} یک کارت کشید که قابل بازی است.',
      );
    }

    return _advanceTurn(
      state.copyWith(
        players: updatedPlayers,
        drawPile: res.drawPile,
        discardPile: res.discardPile,
        statusMessage: '${player.name} یک کارت کشید و نوبت تمام شد.',
      ),
      steps: 1,
    );
  }

  GameState passAfterDraw(GameState state, int playerIndex) {
    if (playerIndex != state.currentPlayerIndex ||
        state.phase != TurnPhase.awaitingDrawDecision) {
      return state;
    }
    return _advanceTurn(
      state.copyWith(
        clearDrawnCardId: true,
        phase: TurnPhase.playing,
      ),
      steps: 1,
    );
  }

  GameState callUno(GameState state, int playerIndex) {
    final updated = List<Player>.from(state.players);
    updated[playerIndex] = updated[playerIndex].copyWith(saidUno: true);
    return state.copyWith(
      players: updated,
      statusMessage: '${updated[playerIndex].name} اعلام UNO کرد!',
    );
  }

  GameState catchUnoPenalty(GameState state, int targetPlayerIndex) {
    final target = state.players[targetPlayerIndex];
    if (target.hand.length != 1 || target.saidUno) return state;

    final res = drawCardsFromDeck(state.drawPile, state.discardPile, 2);
    final updated = List<Player>.from(state.players);
    updated[targetPlayerIndex] = target.copyWith(
      hand: [...target.hand, ...res.drawn],
      saidUno: false,
    );
    return state.copyWith(
      players: updated,
      drawPile: res.drawPile,
      discardPile: res.discardPile,
      statusMessage:
          '${target.name} UNO نگفت و ۲ کارت جریمه شد!',
    );
  }

  GameState _advanceTurn(GameState state, {required int steps}) {
    final nextIdx = nextPlayerIndex(state, steps: steps);
    final nextPlayer = state.players[nextIdx];
    final shouldMask =
        state.mode == GameModeType.localMultiplayer && nextPlayer.isHuman;

    return state.copyWith(
      currentPlayerIndex: nextIdx,
      clearDrawnCardId: true,
      phase: shouldMask ? TurnPhase.awaitingPassDevice : TurnPhase.playing,
    );
  }
}
