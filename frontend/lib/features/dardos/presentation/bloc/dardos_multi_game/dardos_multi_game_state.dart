import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';

enum DardosMultiGameStatus { initial, loading, success, error }

class DardosMultiGameState extends Equatable {
  final DardosMultiGameStatus status;
  final List<DardosGameEntity> games;
  final String? error;

  const DardosMultiGameState({
    this.status = DardosMultiGameStatus.initial,
    this.games = const [],
    this.error,
  });

  DardosMultiGameState copyWith({
    DardosMultiGameStatus? status,
    List<DardosGameEntity>? games,
    String? error,
  }) {
    return DardosMultiGameState(
      status: status ?? this.status,
      games: games ?? this.games,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, games, error];
}
