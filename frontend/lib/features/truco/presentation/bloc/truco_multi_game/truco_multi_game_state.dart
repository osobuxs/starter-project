import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';

enum TrucoMultiGameStatus { initial, loading, loaded, error }

class TrucoMultiGameState extends Equatable {
  final TrucoMultiGameStatus status;

  /// Newest first, as returned by the repository.
  final List<TrucoGame> playingGames;
  final List<TrucoGame> finishedGames;
  final String? error;

  const TrucoMultiGameState({
    this.status = TrucoMultiGameStatus.initial,
    this.playingGames = const [],
    this.finishedGames = const [],
    this.error,
  });

  List<TrucoGame> get allGames => [...playingGames, ...finishedGames];

  TrucoMultiGameState copyWith({
    TrucoMultiGameStatus? status,
    List<TrucoGame>? playingGames,
    List<TrucoGame>? finishedGames,
    String? error,
  }) {
    return TrucoMultiGameState(
      status: status ?? this.status,
      playingGames: playingGames ?? this.playingGames,
      finishedGames: finishedGames ?? this.finishedGames,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, playingGames, finishedGames, error];
}
