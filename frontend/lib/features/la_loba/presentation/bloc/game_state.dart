import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

enum GameBlocStatus {
  initial,
  loading,
  loaded,
  gameCreated,
  playing,
  handFinished,
  gameFinished,
  error,
}

class GameState extends Equatable {
  final GameBlocStatus status;
  final GameEntity? game;
  final Map<String, int> currentHandScores; // participantId -> points
  final String? error;

  const GameState({
    this.status = GameBlocStatus.initial,
    this.game,
    this.currentHandScores = const {},
    this.error,
  });

  GameState copyWith({
    GameBlocStatus? status,
    GameEntity? game,
    bool clearGame = false,
    Map<String, int>? currentHandScores,
    String? error,
    bool clearError = false,
  }) {
    return GameState(
      status: status ?? this.status,
      game: clearGame ? null : (game ?? this.game),
      currentHandScores: currentHandScores ?? this.currentHandScores,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    game,
    currentHandScores,
    error,
  ];
}
