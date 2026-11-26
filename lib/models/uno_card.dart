import 'package:flutter/material.dart';

enum CardColor { red, blue, green, yellow, wild }

enum CardValue {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  skip,
  reverse,
  drawTwo,
  wild,
  wildDrawFour,
}

class UnoCard {
  final String id;
  final CardColor color;
  final CardValue value;

  const UnoCard({
    required this.id,
    required this.color,
    required this.value,
  });

  bool get isWild =>
      value == CardValue.wild || value == CardValue.wildDrawFour;

  bool get isAction =>
      value == CardValue.skip ||
      value == CardValue.reverse ||
      value == CardValue.drawTwo;

  int get points {
    switch (value) {
      case CardValue.zero:
        return 0;
      case CardValue.one:
        return 1;
      case CardValue.two:
        return 2;
      case CardValue.three:
        return 3;
      case CardValue.four:
        return 4;
      case CardValue.five:
        return 5;
      case CardValue.six:
        return 6;
      case CardValue.seven:
        return 7;
      case CardValue.eight:
        return 8;
      case CardValue.nine:
        return 9;
      case CardValue.skip:
      case CardValue.reverse:
      case CardValue.drawTwo:
        return 20;
      case CardValue.wild:
      case CardValue.wildDrawFour:
        return 50;
    }
  }

  String get displayLabel {
    switch (value) {
      case CardValue.zero:
        return '0';
      case CardValue.one:
        return '1';
      case CardValue.two:
        return '2';
      case CardValue.three:
        return '3';
      case CardValue.four:
        return '4';
      case CardValue.five:
        return '5';
      case CardValue.six:
        return '6';
      case CardValue.seven:
        return '7';
      case CardValue.eight:
        return '8';
      case CardValue.nine:
        return '9';
      case CardValue.skip:
        return '⊘';
      case CardValue.reverse:
        return '⇄';
      case CardValue.drawTwo:
        return '+2';
      case CardValue.wild:
        return 'W';
      case CardValue.wildDrawFour:
        return '+4';
    }
  }

  Color get uiColor {
    switch (color) {
      case CardColor.red:
        return const Color(0xFFE11D48);
      case CardColor.blue:
        return const Color(0xFF2563EB);
      case CardColor.green:
        return const Color(0xFF16A34A);
      case CardColor.yellow:
        return const Color(0xFFEAB308);
      case CardColor.wild:
        return const Color(0xFF1E293B);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.name,
        'value': value.name,
      };

  factory UnoCard.fromJson(Map<String, dynamic> json) => UnoCard(
        id: json['id'] as String,
        color: CardColor.values.byName(json['color'] as String),
        value: CardValue.values.byName(json['value'] as String),
      );
}
