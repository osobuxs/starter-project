import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

abstract class DardosParticipantEvent extends Equatable {
  const DardosParticipantEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllParticipantsEvent extends DardosParticipantEvent {}

class CreateParticipantEvent extends DardosParticipantEvent {
  final DardosParticipantEntity participant;

  const CreateParticipantEvent({required this.participant});

  @override
  List<Object?> get props => [participant];
}

class UpdateParticipantEvent extends DardosParticipantEvent {
  final DardosParticipantEntity participant;

  const UpdateParticipantEvent({required this.participant});

  @override
  List<Object?> get props => [participant];
}

class DeleteParticipantEvent extends DardosParticipantEvent {
  final String participantId;

  const DeleteParticipantEvent({required this.participantId});

  @override
  List<Object?> get props => [participantId];
}

class CheckAdminStatusEvent extends DardosParticipantEvent {}
