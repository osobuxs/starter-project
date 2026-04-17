import 'package:equatable/equatable.dart';

abstract class ParticipantEvent extends Equatable {
  const ParticipantEvent();

  @override
  List<Object?> get props => [];
}

class CreateParticipantEvent extends ParticipantEvent {
  final String name;
  final String? email;

  const CreateParticipantEvent(this.name, {this.email});

  @override
  List<Object?> get props => [name, email];
}

class UpdateParticipantEvent extends ParticipantEvent {
  final String id;
  final String? name;
  final String? email;

  const UpdateParticipantEvent(this.id, {this.name, this.email});

  @override
  List<Object?> get props => [id, name, email];
}

class DeleteParticipantEvent extends ParticipantEvent {
  final String id;

  const DeleteParticipantEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchAllParticipantsEvent extends ParticipantEvent {
  const FetchAllParticipantsEvent();
}

class CheckAdminStatusEvent extends ParticipantEvent {
  const CheckAdminStatusEvent();
}
