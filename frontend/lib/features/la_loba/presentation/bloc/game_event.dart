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
  final int gameId;
  final String playerName;

  const AddPlayerEvent({required this.gameId, required this.playerName});

  @override
  List<Object?> get props => [gameId, playerName];
}

class StartGameEvent extends GameEvent {
  final int gameId;

  const StartGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class RecordScoreEvent extends GameEvent {
  final int playerId;
  final int points;

  const RecordScoreEvent({required this.playerId, required this.points});

  @override
  List<Object?> get props => [playerId, points];
}

class FinishPartidaEvent extends GameEvent {
  final int gameId;

  const FinishPartidaEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class DoRetryEvent extends GameEvent {
  final int gameId;
  final int playerId;

  const DoRetryEvent({required this.gameId, required this.playerId});

  @override
  List<Object?> get props => [gameId, playerId];
}

class RejectRetryEvent extends GameEvent {
  final int gameId;
  final int playerId;

  const RejectRetryEvent({required this.gameId, required this.playerId});

  @override
  List<Object?> get props => [gameId, playerId];
}

class LoadGameEvent extends GameEvent {
  final int gameId;

  const LoadGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class LoadHistoryEvent extends GameEvent {
  const LoadHistoryEvent();
}
