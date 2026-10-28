import 'package:equatable/equatable.dart';

abstract class TrucoMultiGameEvent extends Equatable {
  const TrucoMultiGameEvent();

  @override
  List<Object?> get props => [];
}

/// (Re)loads every Truco game.
class LoadTrucoGamesEvent extends TrucoMultiGameEvent {
  const LoadTrucoGamesEvent();
}
