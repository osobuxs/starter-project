import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class CreateGameEvent extends GameEvent {
  final String name;

  const CreateGameEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class AddPlayerEvent extends GameEvent {
  final String gameId;
  final String participantId;

  const AddPlayerEvent({required this.gameId, required this.participantId});

  @override
  List<Object?> get props => [gameId, participantId];
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
