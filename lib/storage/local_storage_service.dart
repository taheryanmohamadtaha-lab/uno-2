import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

class LocalStorageService {
  static const _kSettingsKey = 'uno_party_settings_v1';
  static const _kStatsKey = 'uno_party_stats_v1';
  static const _kSavedGameKey = 'uno_party_saved_game_v1';
  static const _kTournamentKey = 'uno_party_tournament_v1';

  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSettings(Map<String, dynamic> data) =>
      saveJson(_kSettingsKey, data);

  Future<Map<String, dynamic>?> loadSettings() => loadJson(_kSettingsKey);

  Future<void> saveStats(Map<String, dynamic> data) =>
      saveJson(_kStatsKey, data);

  Future<Map<String, dynamic>?> loadStats() => loadJson(_kStatsKey);

  Future<void> saveUnfinishedGame(GameState state) =>
      saveJson(_kSavedGameKey, state.toJson());

  Future<GameState?> loadUnfinishedGame() async {
    final data = await loadJson(_kSavedGameKey);
    if (data == null) return null;
    try {
      return GameState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUnfinishedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedGameKey);
  }

  Future<void> saveTournament(Map<String, dynamic> data) =>
      saveJson(_kTournamentKey, data);

  Future<Map<String, dynamic>?> loadTournament() => loadJson(_kTournamentKey);
}
