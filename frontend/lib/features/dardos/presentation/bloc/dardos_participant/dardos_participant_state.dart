import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

enum DardosParticipantStatus { initial, loading, success, error }

class DardosParticipantState extends Equatable {
  final DardosParticipantStatus status;
  final List<DardosParticipantEntity> participants;
  final bool isAdmin;
  final String? error;

  const DardosParticipantState({
    this.status = DardosParticipantStatus.initial,
    this.participants = const [],
    this.isAdmin = false,
    this.error,
  });

  DardosParticipantState copyWith({
    DardosParticipantStatus? status,
    List<DardosParticipantEntity>? participants,
    bool? isAdmin,
    String? error,
    bool clearError = false,
  }) {
    return DardosParticipantState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      isAdmin: isAdmin ?? this.isAdmin,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, participants, isAdmin, error];
}
