import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../game_engine/game_notifier.dart';
import '../game_modes/local_multiplayer_guard.dart';
import '../localization/app_localizations.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../models/uno_card.dart';
import '../settings/app_settings.dart';
import '../widgets/pass_device_overlay.dart';
import '../widgets/uno_card_widget.dart';
import '../widgets/wild_color_dialog.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);
    final rulesEngine = ref.watch(rulesEngineProvider);
    const guard = LocalMultiplayerGuard();

    if (state == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.t('back_home')),
          ),
        ),
      );
    }

    final bgColors = AppThemes.backgroundGradients[settings.backgroundStyle] ??
        AppThemes.backgroundGradients['midnight']!;
    final tableColor =
        AppThemes.tableColors[settings.tableStyle] ?? const Color(0xFF0F5132);

    final activePlayer = state.mode == GameModeType.localMultiplayer
        ? state.currentPlayer
        : state.players.firstWhere((p) => p.isHuman, orElse: () => state.players.first);

    final activeIdx = state.players.indexOf(activePlayer);
    final opponents = [
      for (int i = 0; i < state.players.length; i++)
        if (i != activeIdx) (index: i, player: state.players[i]),
    ];

    final isMyTurn = state.currentPlayerIndex == activeIdx &&
        state.phase != TurnPhase.finished;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(context, loc, state),
                  _buildOpponentsRow(opponents, state, ref, loc),
                  Expanded(
                    child: Center(
                      child: _build3DTable(
                        context,
                        ref,
                        state,
                        tableColor,
                        settings.cardBackStyle,
                        isMyTurn,
                        loc,
                      ),
                    ),
                  ),
                  _buildStatusBanner(state, loc),
                  _buildActionBar(context, ref, state, activePlayer, isMyTurn, loc),
                  _buildPlayerHand(
                    context,
                    ref,
                    state,
                    activePlayer,
                    isMyTurn,
                    rulesEngine,
                    settings.cardBackStyle,
                  ),
                ],
              ),
              if (state.phase == TurnPhase.awaitingWildColor)
                WildColorDialog(
                  title: loc.t('choose_color'),
                  onSelected: (c) =>
                      ref.read(gameProvider.notifier).selectWildColor(c),
                ),
              if (state.phase == TurnPhase.awaitingPlusFourChallenge &&
                  state.currentPlayer.isHuman)
                _buildPlusFourChallengeModal(ref, loc),
              if (guard.shouldHideHands(state))
                PassDeviceOverlay(
                  title: loc.t('pass_device_title'),
                  playerName: state.currentPlayer.name,
                  emoji: characterById(state.currentPlayer.characterId).emoji,
                  buttonLabel: loc.t('ready_to_play'),
                  onReady: () =>
                      ref.read(gameProvider.notifier).confirmPassDevice(),
                ),
              if (state.phase == TurnPhase.finished)
                _buildWinnerOverlay(context, state, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppLocalizations loc,
    GameState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  state.direction == 1 ? Icons.rotate_right : Icons.rotate_left,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${loc.t('active_color')}: ${_colorName(state.activeColor, loc)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _colorValue(state.activeColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🃏 ${state.drawPile.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentsRow(
    List<({int index, dynamic player})> opponents,
    GameState state,
    WidgetRef ref,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: opponents.map((entry) {
          final p = entry.player;
          final char = characterById(p.characterId);
          final isTurn = state.currentPlayerIndex == entry.index;
          final canCatch = p.hand.length == 1 && !p.saidUno;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTurn ? char.primaryColor.withOpacity(0.35) : Colors.black38,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isTurn ? Colors.amberAccent : Colors.white24,
                width: isTurn ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(char.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${p.hand.length} ${loc.t('cards_left')}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                if (canCatch) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        ref.read(gameProvider.notifier).catchUno(entry.index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+2!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _build3DTable(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    Color tableColor,
    String cardBackStyle,
    bool isMyTurn,
    AppLocalizations loc,
  ) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(0.24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(110),
          gradient: RadialGradient(
            colors: [
              Color.lerp(tableColor, Colors.white, 0.14)!,
              tableColor,
              Color.lerp(tableColor, Colors.black, 0.35)!,
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD97706),
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UnoCardWidget(
              faceDown: true,
              cardBackStyle: cardBackStyle,
              playable: isMyTurn && state.phase == TurnPhase.playing,
              onTap: isMyTurn && state.phase == TurnPhase.playing
                  ? () => ref.read(gameProvider.notifier).drawCard()
                  : null,
            ),
            const SizedBox(width: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: UnoCardWidget(
                key: ValueKey(state.topDiscard.id),
                card: state.topDiscard,
                cardBackStyle: cardBackStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(GameState state, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        state.statusMessage.isEmpty ? state.currentPlayer.name : state.statusMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    dynamic activePlayer,
    bool isMyTurn,
    AppLocalizations loc,
  ) {
    final canUno = activePlayer.hand.length <= 2 && !activePlayer.saidUno;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: isMyTurn && state.phase == TurnPhase.playing
                ? () => ref.read(gameProvider.notifier).drawCard()
                : null,
            icon: const Icon(Icons.layers),
            label: Text(loc.t('draw_card')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
          if (state.phase == TurnPhase.awaitingDrawDecision && isMyTurn)
            ElevatedButton(
              onPressed: () => ref.read(gameProvider.notifier).passAfterDraw(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64748B),
                foregroundColor: Colors.white,
              ),
              child: Text(loc.t('pass_turn')),
            ),
          ElevatedButton(
            onPressed: canUno ? () => ref.read(gameProvider.notifier).callUno() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text(
              loc.t('uno_button'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHand(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    dynamic activePlayer,
    bool isMyTurn,
    dynamic rulesEngine,
    String cardBackStyle,
  ) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: activePlayer.hand.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final card = activePlayer.hand[idx] as UnoCard;
          final canPlay = isMyTurn && rulesEngine.isCardPlayable(state, card);
          return UnoCardWidget(
            card: card,
            playable: canPlay,
            cardBackStyle: cardBackStyle,
            onTap: canPlay
                ? () => ref.read(gameProvider.notifier).playHumanCard(card)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildPlusFourChallengeModal(WidgetRef ref, AppLocalizations loc) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: const Color(0xFF162038),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡ +4', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                Text(
                  loc.t('challenge_plus4'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => ref
                          .read(gameProvider.notifier)
                          .resolvePlusFourChallenge(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(loc.t('challenge_plus4')),
                    ),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(gameProvider.notifier)
                          .resolvePlusFourChallenge(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(loc.t('accept_plus4')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerOverlay(
    BuildContext context,
    GameState state,
    AppLocalizations loc,
  ) {
    final winner = state.players[state.winnerIndex ?? 0];
    final char = characterById(winner.characterId);
    return Container(
      color: Colors.black87,
      child: Center(
        child: Card(
          color: const Color(0xFF131C31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.amberAccent, width: 2),
          ),
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏆 ${char.emoji}', style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                Text(
                  loc.t('winner_title'),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  winner.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  char.winQuoteFa,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(loc.t('back_home')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorValue(CardColor c) {
    switch (c) {
      case CardColor.red:
        return const Color(0xFFE11D48);
      case CardColor.blue:
        return const Color(0xFF2563EB);
      case CardColor.green:
        return const Color(0xFF16A34A);
      case CardColor.yellow:
        return const Color(0xFFEAB308);
      case CardColor.wild:
        return Colors.white;
    }
  }

  String _colorName(CardColor c, AppLocalizations loc) {
    switch (c) {
      case CardColor.red:
        return loc.t('red');
      case CardColor.blue:
        return loc.t('blue');
      case CardColor.green:
        return loc.t('green');
      case CardColor.yellow:
        return loc.t('yellow');
      case CardColor.wild:
        return 'Wild';
    }
  }
}
