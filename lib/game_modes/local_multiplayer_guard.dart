import '../models/game_state.dart';

class LocalMultiplayerGuard {
  const LocalMultiplayerGuard();

  bool shouldHideHands(GameState state) {
    return state.mode == GameModeType.localMultiplayer &&
        state.phase == TurnPhase.awaitingPassDevice;
  }

  String nextPlayerPrompt(GameState state, String lang) {
    final name = state.currentPlayer.name;
    return lang == 'fa'
        ? 'گوشی را به $name تحویل دهید'
        : 'Pass device to $name';
  }
}
