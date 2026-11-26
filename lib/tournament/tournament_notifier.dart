import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import '../storage/local_storage_service.dart';

class TournamentState {
  final int currentStage; // 1 = Quarterfinal, 2 = Semifinal, 3 = Final
  final int totalPoints;
  final int tournamentsWon;
  final bool inProgress;

  const TournamentState({
    this.currentStage = 1,
    this.totalPoints = 0,
    this.tournamentsWon = 0,
    this.inProgress = false,
  });

  TournamentState copyWith({
    int? currentStage,
    int? totalPoints,
    int? tournamentsWon,
    bool? inProgress,
  }) {
    return TournamentState(
      currentStage: currentStage ?? this.currentStage,
      totalPoints: totalPoints ?? this.totalPoints,
      tournamentsWon: tournamentsWon ?? this.tournamentsWon,
      inProgress: inProgress ?? this.inProgress,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStage': currentStage,
        'totalPoints': totalPoints,
        'tournamentsWon': tournamentsWon,
        'inProgress': inProgress,
      };

  factory TournamentState.fromJson(Map<String, dynamic> json) =>
      TournamentState(
        currentStage: json['currentStage'] as int? ?? 1,
        totalPoints: json['totalPoints'] as int? ?? 0,
        tournamentsWon: json['tournamentsWon'] as int? ?? 0,
        inProgress: json['inProgress'] as bool? ?? false,
      );
}

class TournamentNotifier extends StateNotifier<TournamentState> {
  final LocalStorageService _storage;

  TournamentNotifier(this._storage) : super(const TournamentState()) {
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadTournament();
    if (data != null) {
      state = TournamentState.fromJson(data);
    }
  }

  Future<void> startTournament() async {
    state = state.copyWith(currentStage: 1, inProgress: true);
    await _storage.saveTournament(state.toJson());
  }

  Future<void> recordStageResult({required bool won, required int points}) async {
    if (!state.inProgress) return;
    if (!won) {
      state = state.copyWith(currentStage: 1, inProgress: false);
    } else if (state.currentStage >= 3) {
      state = state.copyWith(
        currentStage: 1,
        totalPoints: state.totalPoints + points + 200,
        tournamentsWon: state.tournamentsWon + 1,
        inProgress: false,
      );
    } else {
      state = state.copyWith(
        currentStage: state.currentStage + 1,
        totalPoints: state.totalPoints + points,
      );
    }
    await _storage.saveTournament(state.toJson());
  }
}

final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, TournamentState>(
  (ref) => TournamentNotifier(ref.watch(storageServiceProvider)),
);
