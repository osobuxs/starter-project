import 'package:equatable/equatable.dart';

import 'player.dart';

class GameOverResult extends Equatable {
  final bool isGameOver;
  final List<PlayerEntity> retryCandidates;
  final List<PlayerEntity> autoEliminated;
  final PlayerEntity? winner;

  const GameOverResult({
    required this.isGameOver,
    this.retryCandidates = const [],
    this.autoEliminated = const [],
    this.winner,
  });

  bool get hasRetryCandidates => retryCandidates.isNotEmpty;

  @override
  List<Object?> get props => [
    isGameOver,
    retryCandidates,
    autoEliminated,
    winner,
  ];
}
