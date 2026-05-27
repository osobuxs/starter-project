import 'package:equatable/equatable.dart';

abstract class DardosMultiGameEvent extends Equatable {
  const DardosMultiGameEvent();

  @override
  List<Object?> get props => [];
}

class LoadGamesEvent extends DardosMultiGameEvent {}

class LoadGamesByModeEvent extends DardosMultiGameEvent {
  final String mode;

  const LoadGamesByModeEvent({required this.mode});

  @override
  List<Object?> get props => [mode];
}

class RefreshGamesEvent extends DardosMultiGameEvent {}
