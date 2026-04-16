import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';

enum GameBlocStatus {
  initial,
  loading,
  gameCreated,
  playing,
  partidaFinished,
  retryOffered,
  gameOver,
  historyLoaded,
  error,
}

class GameState extends Equatable {
  final GameBlocStatus status;
  final GameEntity? game;
  final List<GameEntity> games;
  final Map<int, int> currentPartidaScores;
  final List<PlayerEntity> retryCandidates;
  final int currentPartidaNumber;
  final int? currentPartidaId;
  final String? error;

  const GameState({
    this.status = GameBlocStatus.initial,
    this.game,
    this.games = const [],
    this.currentPartidaScores = const {},
    this.retryCandidates = const [],
    this.currentPartidaNumber = 0,
    this.currentPartidaId,
    this.error,
  });

  GameState copyWith({
    GameBlocStatus? status,
    GameEntity? game,
    bool clearGame = false,
    List<GameEntity>? games,
    Map<int, int>? currentPartidaScores,
    List<PlayerEntity>? retryCandidates,
    int? currentPartidaNumber,
    int? currentPartidaId,
    bool clearPartidaId = false,
    String? error,
    bool clearError = false,
  }) {
    return GameState(
      status: status ?? this.status,
      game: clearGame ? null : (game ?? this.game),
      games: games ?? this.games,
      currentPartidaScores: currentPartidaScores ?? this.currentPartidaScores,
      retryCandidates: retryCandidates ?? this.retryCandidates,
      currentPartidaNumber: currentPartidaNumber ?? this.currentPartidaNumber,
      currentPartidaId: clearPartidaId
          ? null
          : (currentPartidaId ?? this.currentPartidaId),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    game,
    games,
    currentPartidaScores,
    retryCandidates,
    currentPartidaNumber,
    currentPartidaId,
    error,
  ];
}
