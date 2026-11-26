import 'dart:math';

import '../models/game_state.dart';
import '../models/player.dart';
import '../models/uno_card.dart';
import '../rules/rules_engine.dart';

/// Public-information-only view for AI so it never sees opponents' hidden hands.
class AiPublicView {
  final int myIndex;
  final List<UnoCard> myHand;
  final CardColor activeColor;
  final UnoCard topDiscard;
  final List<int> opponentHandCounts;
  final int nextOpponentCount;
  final int pendingDrawCount;
  final bool allowStacking;

  const AiPublicView({
    required this.myIndex,
    required this.myHand,
    required this.activeColor,
    required this.topDiscard,
    required this.opponentHandCounts,
    required this.nextOpponentCount,
    required this.pendingDrawCount,
    required this.allowStacking,
  });

  factory AiPublicView.fromState(GameState state, int aiIndex) {
    final nextIdx = ((aiIndex + state.direction) % state.players.length +
            state.players.length) %
        state.players.length;
    return AiPublicView(
      myIndex: aiIndex,
      myHand: List<UnoCard>.from(state.players[aiIndex].hand),
      activeColor: state.activeColor,
      topDiscard: state.topDiscard,
      opponentHandCounts: [
        for (int i = 0; i < state.players.length; i++)
          if (i != aiIndex) state.players[i].hand.length,
      ],
      nextOpponentCount: state.players[nextIdx].hand.length,
      pendingDrawCount: state.pendingDrawCount,
      allowStacking: state.rules.allowStacking,
    );
  }
}

class AiDecision {
  final UnoCard? cardToPlay;
  final CardColor? wildColor;
  final bool shouldDraw;
  final bool shouldCallUno;

  const AiDecision({
    this.cardToPlay,
    this.wildColor,
    this.shouldDraw = false,
    this.shouldCallUno = false,
  });
}

class AiEngine {
  final RulesEngine rulesEngine;
  final Random _random;

  AiEngine({required this.rulesEngine, Random? random})
      : _random = random ?? Random();

  AiDecision decideMove(GameState state, int aiIndex) {
    final player = state.players[aiIndex];
    final view = AiPublicView.fromState(state, aiIndex);
    final playable = view.myHand
        .where((c) => rulesEngine.isCardPlayable(state, c))
        .toList();

    if (playable.isEmpty) {
      return const AiDecision(shouldDraw: true);
    }

    final difficulty = player.aiDifficulty ?? AiDifficulty.medium;
    UnoCard chosen;

    switch (difficulty) {
      case AiDifficulty.easy:
        chosen = playable[_random.nextInt(playable.length)];
        break;
      case AiDifficulty.medium:
        chosen = _chooseMedium(playable, view);
        break;
      case AiDifficulty.hard:
        chosen = _chooseHard(playable, view);
        break;
    }

    final wildColor = chosen.isWild ? _pickBestColor(view.myHand) : null;
    final willHaveOneLeft = view.myHand.length == 2;
    final callsUno = willHaveOneLeft &&
        (difficulty != AiDifficulty.easy || _random.nextDouble() > 0.35);

    return AiDecision(
      cardToPlay: chosen,
      wildColor: wildColor,
      shouldCallUno: callsUno,
    );
  }

  bool decidePlusFourChallenge(GameState state, int aiIndex) {
    final difficulty = state.players[aiIndex].aiDifficulty ?? AiDifficulty.medium;
    if (difficulty == AiDifficulty.easy) {
      return _random.nextBool();
    }
    if (difficulty == AiDifficulty.medium) {
      return _random.nextDouble() < 0.35;
    }
    // Hard AI challenges more often if offender has many cards (higher chance of bluff)
    final ch = state.pendingChallenge;
    if (ch == null) return false;
    final offenderCards = state.players[ch.offenderIndex].hand.length;
    return offenderCards >= 5 ? _random.nextDouble() < 0.55 : false;
  }

  UnoCard _chooseMedium(List<UnoCard> playable, AiPublicView view) {
    if (view.nextOpponentCount <= 2) {
      final attack = playable.where((c) =>
          c.value == CardValue.drawTwo ||
          c.value == CardValue.skip ||
          c.value == CardValue.reverse);
      if (attack.isNotEmpty) return attack.first;
    }
    final nonWild = playable.where((c) => !c.isWild).toList();
    if (nonWild.isNotEmpty) {
      nonWild.sort((a, b) => b.points.compareTo(a.points));
      return nonWild.first;
    }
    return playable.first;
  }

  UnoCard _chooseHard(List<UnoCard> playable, AiPublicView view) {
    final minOpp = view.opponentHandCounts.reduce(min);

    // Prioritize +2 / Skip / Reverse when any opponent is close to winning
    if (minOpp <= 2) {
      final highImpact = playable.where((c) =>
          c.value == CardValue.drawTwo ||
          c.value == CardValue.skip ||
          c.value == CardValue.reverse);
      if (highImpact.isNotEmpty) return highImpact.first;
    }

    // Avoid bluffing +4 if we have matching color, unless desperate
    final hasColorMatch = view.myHand.any((c) => c.color == view.activeColor);
    final safeCards = playable
        .where((c) => !(c.value == CardValue.wildDrawFour && hasColorMatch))
        .toList();

    final pool = safeCards.isNotEmpty ? safeCards : playable;
    final nonWild = pool.where((c) => !c.isWild).toList();
    if (nonWild.isNotEmpty) {
      // Shed highest point cards first while keeping wilds as backup
      nonWild.sort((a, b) => b.points.compareTo(a.points));
      return nonWild.first;
    }
    return pool.first;
  }

  CardColor _pickBestColor(List<UnoCard> hand) {
    final counts = <CardColor, int>{
      CardColor.red: 0,
      CardColor.blue: 0,
      CardColor.green: 0,
      CardColor.yellow: 0,
    };
    for (final c in hand) {
      if (counts.containsKey(c.color)) {
        counts[c.color] = counts[c.color]! + 1;
      }
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
