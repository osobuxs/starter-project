import 'package:equatable/equatable.dart';

abstract class TrucoParticipantEvent extends Equatable {
  const TrucoParticipantEvent();

  @override
  List<Object?> get props => [];
}

class FetchTrucoParticipantsEvent extends TrucoParticipantEvent {
  const FetchTrucoParticipantsEvent();
}

class CreateTrucoParticipantEvent extends TrucoParticipantEvent {
  final String name;

  const CreateTrucoParticipantEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateTrucoParticipantEvent extends TrucoParticipantEvent {
  final String id;
  final String name;

  const UpdateTrucoParticipantEvent(this.id, this.name);

  @override
  List<Object?> get props => [id, name];
}

class DeleteTrucoParticipantEvent extends TrucoParticipantEvent {
  final String id;

  const DeleteTrucoParticipantEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CheckTrucoAdminStatusEvent extends TrucoParticipantEvent {
  const CheckTrucoAdminStatusEvent();
}
