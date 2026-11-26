import '../models/game_state.dart';
import '../models/uno_card.dart';

/// Future V2 Online Multiplayer Contract.
/// Strictly decoupled from V1 offline game engine; no network calls in V1.
abstract class OnlineGameTransport {
  Future<void> connect(String roomCode, String playerId);
  Future<void> disconnect();
  Stream<GameState> watchRoomState();
  Future<void> sendPlayCard(UnoCard card, {CardColor? wildColor});
  Future<void> sendDrawCard();
  Future<void> sendCallUno();
}
