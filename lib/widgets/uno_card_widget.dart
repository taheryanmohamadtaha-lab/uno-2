import 'package:flutter/material.dart';

import '../models/uno_card.dart';

class UnoCardWidget extends StatelessWidget {
  final UnoCard? card;
  final bool faceDown;
  final bool playable;
  final String cardBackStyle;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const UnoCardWidget({
    super.key,
    this.card,
    this.faceDown = false,
    this.playable = false,
    this.cardBackStyle = 'classic_dark',
    this.onTap,
    this.width = 76,
    this.height = 112,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = playable ? Colors.white : Colors.white.withOpacity(0.75);
    final baseColor = faceDown
        ? _backColor(cardBackStyle)
        : (card?.uiColor ?? const Color(0xFF1E293B));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, playable ? -10 : 0, 0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          // 3D card thickness & drop shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              offset: const Offset(0, 7),
              blurRadius: 10,
            ),
            if (playable)
              BoxShadow(
                color: Colors.amberAccent.withOpacity(0.65),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.18)!,
              baseColor,
              Color.lerp(baseColor, Colors.black, 0.25)!,
            ],
          ),
          border: Border.all(color: borderColor, width: playable ? 2.6 : 1.8),
        ),
        child: Stack(
          children: [
            // Glossy light reflection overlay
            Positioned(
              top: 4,
              left: 6,
              right: 6,
              height: height * 0.36,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.28),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            if (faceDown)
              Center(
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amberAccent, width: 2),
                    ),
                    child: const Text(
                      'UNO',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              )
            else if (card != null) ...[
              Positioned(
                top: 6,
                left: 8,
                child: Text(
                  card!.displayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: width * 0.68,
                  height: height * 0.56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      card!.displayLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 8,
                child: Text(
                  card!.displayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _backColor(String style) {
    switch (style) {
      case 'royal_gold':
        return const Color(0xFF78350F);
      case 'neon_cyber':
        return const Color(0xFF312E81);
      default:
        return const Color(0xFF0F172A);
    }
  }
}
