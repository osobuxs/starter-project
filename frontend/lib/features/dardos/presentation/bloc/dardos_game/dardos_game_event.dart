import 'package:equatable/equatable.dart';

abstract class DardosGameEvent extends Equatable {
  const DardosGameEvent();

  @override
  List<Object?> get props => [];
}

class CreateDardosGameEvent extends DardosGameEvent {
  final String name;
  final String mode;
  final bool doubleOut;
  final int sets;
  final int legs;
  final List<String> playerIds;
  final String createdBy;

  const CreateDardosGameEvent({
    required this.name,
    required this.mode,
    required this.doubleOut,
    required this.sets,
    required this.legs,
    required this.playerIds,
    required this.createdBy,
  });

  @override
  List<Object?> get props =>
      [name, mode, doubleOut, sets, legs, playerIds, createdBy];
}

class LoadDardosGameEvent extends DardosGameEvent {
  final String gameId;

  const LoadDardosGameEvent({required this.gameId});

  @override
  List<Object?> get props => [gameId];
}

class AcquireAnnotatorEvent extends DardosGameEvent {
  final String gameId;
  final String deviceId;

  const AcquireAnnotatorEvent({required this.gameId, required this.deviceId});

  @override
  List<Object?> get props => [gameId, deviceId];
}

class ReleaseAnnotatorEvent extends DardosGameEvent {
  final String gameId;
  final String deviceId;

  const ReleaseAnnotatorEvent({required this.gameId, required this.deviceId});

  @override
  List<Object?> get props => [gameId, deviceId];
}

class RecordThrowEvent extends DardosGameEvent {
  final int number;
  final int multiplier;
  final bool isMiss;

  const RecordThrowEvent({
    required this.number,
    required this.multiplier,
    required this.isMiss,
  });

  @override
  List<Object?> get props => [number, multiplier, isMiss];
}

class UndoLastThrowEvent extends DardosGameEvent {}

class CancelGameEvent extends DardosGameEvent {
  final String gameId;
  final String cancelledBy;
  final bool isAdmin;

  const CancelGameEvent({
    required this.gameId,
    required this.cancelledBy,
    required this.isAdmin,
  });

  @override
  List<Object?> get props => [gameId, cancelledBy, isAdmin];
}

class AcknowledgeBannerEvent extends DardosGameEvent {}
