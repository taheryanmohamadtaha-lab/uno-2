import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import '../storage/local_storage_service.dart';

class MatchRecord {
  final String dateIso;
  final String mode;
  final bool won;
  final int score;

  const MatchRecord({
    required this.dateIso,
    required this.mode,
    required this.won,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'dateIso': dateIso,
        'mode': mode,
        'won': won,
        'score': score,
      };

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
        dateIso: json['dateIso'] as String,
        mode: json['mode'] as String,
        won: json['won'] as bool,
        score: json['score'] as int,
      );
}

class StatsState {
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int bestScore;
  final int coins;
  final List<String> unlockedCharacters;
  final List<String> unlockedCardBacks;
  final List<String> unlockedAchievements;
  final List<MatchRecord> history;

  const StatsState({
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.bestScore = 0,
    this.coins = 200,
    this.unlockedCharacters = const ['aria', 'parisa', 'kian', 'niki'],
    this.unlockedCardBacks = const ['classic_dark', 'royal_gold'],
    this.unlockedAchievements = const [],
    this.history = const [],
  });

  StatsState copyWith({
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? bestScore,
    int? coins,
    List<String>? unlockedCharacters,
    List<String>? unlockedCardBacks,
    List<String>? unlockedAchievements,
    List<MatchRecord>? history,
  }) {
    return StatsState(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      bestScore: bestScore ?? this.bestScore,
      coins: coins ?? this.coins,
      unlockedCharacters: unlockedCharacters ?? this.unlockedCharacters,
      unlockedCardBacks: unlockedCardBacks ?? this.unlockedCardBacks,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'losses': losses,
        'bestScore': bestScore,
        'coins': coins,
        'unlockedCharacters': unlockedCharacters,
        'unlockedCardBacks': unlockedCardBacks,
        'unlockedAchievements': unlockedAchievements,
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory StatsState.fromJson(Map<String, dynamic> json) => StatsState(
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
        coins: json['coins'] as int? ?? 200,
        unlockedCharacters:
            (json['unlockedCharacters'] as List?)?.cast<String>() ??
                const ['aria', 'parisa', 'kian', 'niki'],
        unlockedCardBacks:
            (json['unlockedCardBacks'] as List?)?.cast<String>() ??
                const ['classic_dark', 'royal_gold'],
        unlockedAchievements:
            (json['unlockedAchievements'] as List?)?.cast<String>() ?? const [],
        history: (json['history'] as List?)
                ?.map((e) => MatchRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class StatsNotifier extends StateNotifier<StatsState> {
  final LocalStorageService _storage;

  StatsNotifier(this._storage) : super(const StatsState()) {
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadStats();
    if (data != null) {
      state = StatsState.fromJson(data);
    }
  }

  Future<void> recordMatch({
    required String mode,
    required bool won,
    required int score,
  }) async {
    final newWins = state.wins + (won ? 1 : 0);
    final newLosses = state.losses + (won ? 0 : 1);
    final newCoins = state.coins + (won ? 75 : 15);
    final newBest = score > state.bestScore ? score : state.bestScore;
    final ach = Set<String>.from(state.unlockedAchievements);
    if (newWins >= 1) ach.add('first_win');
    if (newWins >= 5) ach.add('five_wins');
    if (score >= 150) ach.add('high_scorer');

    final updated = state.copyWith(
      gamesPlayed: state.gamesPlayed + 1,
      wins: newWins,
      losses: newLosses,
      bestScore: newBest,
      coins: newCoins,
      unlockedAchievements: ach.toList(),
      history: [
        MatchRecord(
          dateIso: DateTime.now().toIso8601String(),
          mode: mode,
          won: won,
          score: score,
        ),
        ...state.history.take(19),
      ],
    );
    state = updated;
    await _storage.saveStats(updated.toJson());
  }

  Future<bool> unlockCharacter(String id, int cost) async {
    if (state.unlockedCharacters.contains(id) || state.coins < cost) {
      return false;
    }
    final updated = state.copyWith(
      coins: state.coins - cost,
      unlockedCharacters: [...state.unlockedCharacters, id],
    );
    state = updated;
    await _storage.saveStats(updated.toJson());
    return true;
  }

  Future<bool> unlockCardBack(String id, int cost) async {
    if (state.unlockedCardBacks.contains(id) || state.coins < cost) {
      return false;
    }
    final updated = state.copyWith(
      coins: state.coins - cost,
      unlockedCardBacks: [...state.unlockedCardBacks, id],
    );
    state = updated;
    await _storage.saveStats(updated.toJson());
    return true;
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (ref) => StatsNotifier(ref.watch(storageServiceProvider)),
);
