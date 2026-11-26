import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_party/game_modes/local_multiplayer_guard.dart';
import 'package:uno_party/localization/app_localizations.dart';
import 'package:uno_party/models/game_rules_config.dart';
import 'package:uno_party/models/game_state.dart';
import 'package:uno_party/models/player.dart';
import 'package:uno_party/rules/rules_engine.dart';

void main() {
  test('Local multiplayer starts in awaitingPassDevice to hide cards', () {
    final engine = RulesEngine(random: Random(7));
    const guard = LocalMultiplayerGuard();

    final state = engine.createInitialGame(
      mode: GameModeType.localMultiplayer,
      players: const [
        Player(
          id: '1',
          name: 'علی',
          characterId: 'aria',
          isHuman: true,
          hand: [],
        ),
        Player(
          id: '2',
          name: 'سارا',
          characterId: 'parisa',
          isHuman: true,
          hand: [],
        ),
      ],
      rules: const GameRulesConfig(),
    );

    expect(state.phase, TurnPhase.awaitingPassDevice);
    expect(guard.shouldHideHands(state), isTrue);
  });

  test('GameState serializes and restores cleanly for unfinished games', () {
    final engine = RulesEngine(random: Random(9));
    final original = engine.createInitialGame(
      mode: GameModeType.singlePlayerAi,
      players: const [
        Player(
          id: '1',
          name: 'Player',
          characterId: 'aria',
          isHuman: true,
          hand: [],
        ),
        Player(
          id: '2',
          name: 'AI',
          characterId: 'kian',
          isHuman: false,
          aiDifficulty: AiDifficulty.medium,
          hand: [],
        ),
      ],
      rules: const GameRulesConfig(allowStacking: true, sevenZeroRule: true),
    );

    final restored = GameState.fromJson(original.toJson());
    expect(restored.players.length, original.players.length);
    expect(restored.players[0].hand.length, 7);
    expect(restored.rules.allowStacking, isTrue);
    expect(restored.rules.sevenZeroRule, isTrue);
    expect(restored.activeColor, original.activeColor);
  });

  test('Persian and English localizations resolve all core labels', () {
    const fa = AppLocalizations('fa');
    const en = AppLocalizations('en');
    expect(fa.isFa, isTrue);
    expect(fa.t('new_game'), 'بازی جدید');
    expect(en.t('new_game'), 'New Game');
  });
}
