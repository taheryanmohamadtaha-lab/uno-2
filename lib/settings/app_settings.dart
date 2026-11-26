import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_rules_config.dart';
import '../models/player.dart';
import '../storage/local_storage_service.dart';

class AppSettingsState {
  final String language; // 'fa' or 'en'
  final bool darkMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final double animationIntensity; // 0.5 to 1.5
  final AiDifficulty aiDifficulty;
  final String tableStyle;
  final String cardBackStyle;
  final String backgroundStyle;
  final String selectedCharacterId;
  final GameRulesConfig rulesConfig;

  const AppSettingsState({
    this.language = 'fa',
    this.darkMode = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.animationIntensity = 1.0,
    this.aiDifficulty = AiDifficulty.medium,
    this.tableStyle = 'emerald',
    this.cardBackStyle = 'classic_dark',
    this.backgroundStyle = 'midnight',
    this.selectedCharacterId = 'aria',
    this.rulesConfig = const GameRulesConfig(),
  });

  AppSettingsState copyWith({
    String? language,
    bool? darkMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    double? animationIntensity,
    AiDifficulty? aiDifficulty,
    String? tableStyle,
    String? cardBackStyle,
    String? backgroundStyle,
    String? selectedCharacterId,
    GameRulesConfig? rulesConfig,
  }) {
    return AppSettingsState(
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      animationIntensity: animationIntensity ?? this.animationIntensity,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      tableStyle: tableStyle ?? this.tableStyle,
      cardBackStyle: cardBackStyle ?? this.cardBackStyle,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
      rulesConfig: rulesConfig ?? this.rulesConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'darkMode': darkMode,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'animationIntensity': animationIntensity,
        'aiDifficulty': aiDifficulty.name,
        'tableStyle': tableStyle,
        'cardBackStyle': cardBackStyle,
        'backgroundStyle': backgroundStyle,
        'selectedCharacterId': selectedCharacterId,
        'rulesConfig': rulesConfig.toJson(),
      };

  factory AppSettingsState.fromJson(Map<String, dynamic> json) =>
      AppSettingsState(
        language: json['language'] as String? ?? 'fa',
        darkMode: json['darkMode'] as bool? ?? true,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
        animationIntensity:
            (json['animationIntensity'] as num?)?.toDouble() ?? 1.0,
        aiDifficulty: json['aiDifficulty'] != null
            ? AiDifficulty.values.byName(json['aiDifficulty'] as String)
            : AiDifficulty.medium,
        tableStyle: json['tableStyle'] as String? ?? 'emerald',
        cardBackStyle: json['cardBackStyle'] as String? ?? 'classic_dark',
        backgroundStyle: json['backgroundStyle'] as String? ?? 'midnight',
        selectedCharacterId: json['selectedCharacterId'] as String? ?? 'aria',
        rulesConfig: json['rulesConfig'] != null
            ? GameRulesConfig.fromJson(
                json['rulesConfig'] as Map<String, dynamic>,
              )
            : const GameRulesConfig(),
      );
}

final storageServiceProvider = Provider((ref) => LocalStorageService());

class SettingsNotifier extends StateNotifier<AppSettingsState> {
  final LocalStorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadSettings();
    if (data != null) {
      state = AppSettingsState.fromJson(data);
    }
  }

  Future<void> update(AppSettingsState next) async {
    state = next;
    await _storage.saveSettings(next.toJson());
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>(
  (ref) => SettingsNotifier(ref.watch(storageServiceProvider)),
);
