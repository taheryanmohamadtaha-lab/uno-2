import 'package:flutter/material.dart';

class AppThemes {
  static const Map<String, Color> tableColors = {
    'emerald': Color(0xFF0F5132),
    'royal_blue': Color(0xFF132A5E),
    'crimson': Color(0xFF5C162E),
    'obsidian': Color(0xFF1E2235),
  };

  static const Map<String, List<Color>> backgroundGradients = {
    'midnight': [Color(0xFF0B1026), Color(0xFF1A254B)],
    'sunset': [Color(0xFF3E1846), Color(0xFF832743)],
    'forest': [Color(0xFF0A2A22), Color(0xFF164D3E)],
    'ocean': [Color(0xFF09203F), Color(0xFF1B4B72)],
  };

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      fontFamily: 'Tahoma',
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1026),
      fontFamily: 'Tahoma',
    );
  }
}
