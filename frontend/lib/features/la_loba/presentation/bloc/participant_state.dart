import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';

enum ParticipantBlocStatus {
  initial,
  loading,
  loaded,
  created,
  updated,
  deleted,
  error,
}

class ParticipantState extends Equatable {
  final ParticipantBlocStatus status;
  final List<ParticipantEntity> participants;
  final bool isAdmin;
  final String? error;

  const ParticipantState({
    this.status = ParticipantBlocStatus.initial,
    this.participants = const [],
    this.isAdmin = false,
    this.error,
  });

  ParticipantState copyWith({
    ParticipantBlocStatus? status,
    List<ParticipantEntity>? participants,
    bool? isAdmin,
    String? error,
    bool clearError = false,
  }) {
    return ParticipantState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      isAdmin: isAdmin ?? this.isAdmin,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, participants, isAdmin, error];
}
