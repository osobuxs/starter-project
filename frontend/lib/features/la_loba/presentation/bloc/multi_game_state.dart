import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

enum MultiGameBlocStatus {
  initial,
  loading,
  loaded,
  gameCreated,
  gamePaused,
  gameResumed,
  gameFinished,
  error,
}

class MultiGameState extends Equatable {
  final MultiGameBlocStatus status;
  final List<GameEntity> playingGames;
  final List<GameEntity> pausedGames;
  final List<GameEntity> finishedGames;
  final GameEntity? selectedGame;
  final String? error;

  const MultiGameState({
    this.status = MultiGameBlocStatus.initial,
    this.playingGames = const [],
    this.pausedGames = const [],
    this.finishedGames = const [],
    this.selectedGame,
    this.error,
  });

  MultiGameState copyWith({
    MultiGameBlocStatus? status,
    List<GameEntity>? playingGames,
    List<GameEntity>? pausedGames,
    List<GameEntity>? finishedGames,
    GameEntity? selectedGame,
    bool clearSelectedGame = false,
    String? error,
    bool clearError = false,
  }) {
    return MultiGameState(
      status: status ?? this.status,
      playingGames: playingGames ?? this.playingGames,
      pausedGames: pausedGames ?? this.pausedGames,
      finishedGames: finishedGames ?? this.finishedGames,
      selectedGame:
          clearSelectedGame ? null : (selectedGame ?? this.selectedGame),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        playingGames,
        pausedGames,
        finishedGames,
        selectedGame,
        error,
      ];
}
