import 'uno_card.dart';

enum AiDifficulty { easy, medium, hard }

class Player {
  final String id;
  final String name;
  final String characterId;
  final bool isHuman;
  final AiDifficulty? aiDifficulty;
  final List<UnoCard> hand;
  final bool saidUno;

  const Player({
    required this.id,
    required this.name,
    required this.characterId,
    required this.isHuman,
    this.aiDifficulty,
    required this.hand,
    this.saidUno = false,
  });

  Player copyWith({
    String? name,
    String? characterId,
    List<UnoCard>? hand,
    bool? saidUno,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      characterId: characterId ?? this.characterId,
      isHuman: isHuman,
      aiDifficulty: aiDifficulty,
      hand: hand ?? this.hand,
      saidUno: saidUno ?? this.saidUno,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'characterId': characterId,
        'isHuman': isHuman,
        'aiDifficulty': aiDifficulty?.name,
        'hand': hand.map((c) => c.toJson()).toList(),
        'saidUno': saidUno,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        characterId: json['characterId'] as String,
        isHuman: json['isHuman'] as bool,
        aiDifficulty: json['aiDifficulty'] != null
            ? AiDifficulty.values.byName(json['aiDifficulty'] as String)
            : null,
        hand: (json['hand'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        saidUno: json['saidUno'] as bool? ?? false,
      );
}
