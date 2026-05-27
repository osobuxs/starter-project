import 'package:equatable/equatable.dart';

abstract class BottomNavEvent extends Equatable {
  const BottomNavEvent();

  @override
  List<Object?> get props => [];
}

class ChangeTabEvent extends BottomNavEvent {
  final int tabIndex;

  const ChangeTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class SelectGameInIniciarEvent extends BottomNavEvent {
  final String gameId;

  const SelectGameInIniciarEvent(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class UpdateFilterEvent extends BottomNavEvent {
  final String? dateStart;
  final String? dateEnd;
  final String? participantId;
  final String? winnerId;

  const UpdateFilterEvent({
    this.dateStart,
    this.dateEnd,
    this.participantId,
    this.winnerId,
  });

  @override
  List<Object?> get props => [dateStart, dateEnd, participantId, winnerId];
}
