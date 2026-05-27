import 'package:equatable/equatable.dart';

abstract class DardosBottomNavEvent extends Equatable {
  const DardosBottomNavEvent();

  @override
  List<Object?> get props => [];
}

class ChangeTabEvent extends DardosBottomNavEvent {
  final int index;

  const ChangeTabEvent(this.index);

  @override
  List<Object?> get props => [index];
}
