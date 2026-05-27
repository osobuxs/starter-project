import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class CreateGameEvent extends GameEvent {
  final String name;
  final List<String>? participantIds;

  const CreateGameEvent(this.name, {this.participantIds});

  @override
  List<Object?> get props => [name, participantIds];
}

class AddPlayerEvent extends GameEvent {
  final String gameId;
  final String participantId;
  final int? insertIndex;

  const AddPlayerEvent({
    required this.gameId,
    required this.participantId,
    this.insertIndex,
  });

  @override
  List<Object?> get props => [gameId, participantId, insertIndex];
}

class ResolveRetryDecisionEvent extends GameEvent {
  final String participantId;
  final bool rejoin;

  const ResolveRetryDecisionEvent({
    required this.participantId,
    required this.rejoin,
  });

  @override
  List<Object?> get props => [participantId, rejoin];
}

class StartGameEvent extends GameEvent {
  final String gameId;

  const StartGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class RecordScoreEvent extends GameEvent {
  final String participantId;
  final int points;

  const RecordScoreEvent({required this.participantId, required this.points});

  @override
  List<Object?> get props => [participantId, points];
}

class FinishPartidaEvent extends GameEvent {
  final String gameId;

  const FinishPartidaEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class LoadGameEvent extends GameEvent {
  final String gameId;

  const LoadGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class LoadHistoryEvent extends GameEvent {
  const LoadHistoryEvent();
}
