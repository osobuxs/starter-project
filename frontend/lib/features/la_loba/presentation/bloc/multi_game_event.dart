import 'package:equatable/equatable.dart';

abstract class MultiGameEvent extends Equatable {
  const MultiGameEvent();

  @override
  List<Object?> get props => [];
}

class CreateGameEvent extends MultiGameEvent {
  final String gameName;
  final List<String> participantIds;

  const CreateGameEvent(this.gameName, this.participantIds);

  @override
  List<Object?> get props => [gameName, participantIds];
}

class LoadGamesEvent extends MultiGameEvent {
  const LoadGamesEvent();
}

class PauseGameEvent extends MultiGameEvent {
  final String gameId;

  const PauseGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class ResumeGameEvent extends MultiGameEvent {
  final String gameId;

  const ResumeGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class FinishGameEvent extends MultiGameEvent {
  final String gameId;
  final String winnerId;

  const FinishGameEvent(this.gameId, this.winnerId);

  @override
  List<Object?> get props => [gameId, winnerId];
}

class SelectGameEvent extends MultiGameEvent {
  final String gameId;

  const SelectGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}
