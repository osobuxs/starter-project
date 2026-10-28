import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

abstract class TrucoGameEvent extends Equatable {
  const TrucoGameEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the game and starts listening to its realtime updates.
class LoadTrucoGameEvent extends TrucoGameEvent {
  final String gameId;

  const LoadTrucoGameEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

/// Points typed for one team in the hand being entered (may be negative).
class SetTrucoHandPointsEvent extends TrucoGameEvent {
  final TrucoTeamSide side;
  final int points;

  const SetTrucoHandPointsEvent({required this.side, required this.points});

  @override
  List<Object?> get props => [side, points];
}

/// Closes the hand with the entered points.
class ConfirmTrucoHandEvent extends TrucoGameEvent {
  const ConfirmTrucoHandEvent();
}

/// Reopens the last closed hand so its points can be corrected.
class StartEditLastTrucoHandEvent extends TrucoGameEvent {
  const StartEditLastTrucoHandEvent();
}

/// Leaves edit mode restoring the board.
class CancelEditLastTrucoHandEvent extends TrucoGameEvent {
  const CancelEditLastTrucoHandEvent();
}
