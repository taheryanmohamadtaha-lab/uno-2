class GameRulesConfig {
  final bool allowStacking; // Default OFF in standard rules
  final bool sevenZeroRule;
  final bool allowJumpIn;
  final bool drawUntilPlayable;
  final int initialHandSize;

  const GameRulesConfig({
    this.allowStacking = false,
    this.sevenZeroRule = false,
    this.allowJumpIn = false,
    this.drawUntilPlayable = false,
    this.initialHandSize = 7,
  });

  GameRulesConfig copyWith({
    bool? allowStacking,
    bool? sevenZeroRule,
    bool? allowJumpIn,
    bool? drawUntilPlayable,
    int? initialHandSize,
  }) {
    return GameRulesConfig(
      allowStacking: allowStacking ?? this.allowStacking,
      sevenZeroRule: sevenZeroRule ?? this.sevenZeroRule,
      allowJumpIn: allowJumpIn ?? this.allowJumpIn,
      drawUntilPlayable: drawUntilPlayable ?? this.drawUntilPlayable,
      initialHandSize: initialHandSize ?? this.initialHandSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowStacking': allowStacking,
        'sevenZeroRule': sevenZeroRule,
        'allowJumpIn': allowJumpIn,
        'drawUntilPlayable': drawUntilPlayable,
        'initialHandSize': initialHandSize,
      };

  factory GameRulesConfig.fromJson(Map<String, dynamic> json) => GameRulesConfig(
        allowStacking: json['allowStacking'] as bool? ?? false,
        sevenZeroRule: json['sevenZeroRule'] as bool? ?? false,
        allowJumpIn: json['allowJumpIn'] as bool? ?? false,
        drawUntilPlayable: json['drawUntilPlayable'] as bool? ?? false,
        initialHandSize: json['initialHandSize'] as int? ?? 7,
      );
}
