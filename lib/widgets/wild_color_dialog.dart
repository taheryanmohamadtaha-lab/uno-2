import 'package:flutter/material.dart';

import '../models/uno_card.dart';

class WildColorDialog extends StatelessWidget {
  final String title;
  final void Function(CardColor color) onSelected;

  const WildColorDialog({
    super.key,
    required this.title,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131C31),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _colorTile(CardColor.red, const Color(0xFFE11D48)),
                _colorTile(CardColor.blue, const Color(0xFF2563EB)),
                _colorTile(CardColor.green, const Color(0xFF16A34A)),
                _colorTile(CardColor.yellow, const Color(0xFFEAB308)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorTile(CardColor color, Color uiColor) {
    return GestureDetector(
      onTap: () => onSelected(color),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: uiColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: uiColor.withValues(alpha: 0.55),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}
