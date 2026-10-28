import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';

enum TrucoParticipantStatus {
  initial,
  loading,
  loaded,
  created,
  updated,
  deleted,
  error,
}

class TrucoParticipantState extends Equatable {
  final TrucoParticipantStatus status;
  final List<TrucoParticipant> participants;
  final bool isAdmin;
  final String? error;

  const TrucoParticipantState({
    this.status = TrucoParticipantStatus.initial,
    this.participants = const [],
    this.isAdmin = false,
    this.error,
  });

  /// Player names by id (for boards, lists and history).
  Map<String, String> get namesById => {
        for (final participant in participants)
          participant.id: participant.name,
      };

  TrucoParticipantState copyWith({
    TrucoParticipantStatus? status,
    List<TrucoParticipant>? participants,
    bool? isAdmin,
    String? error,
    bool clearError = false,
  }) {
    return TrucoParticipantState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      isAdmin: isAdmin ?? this.isAdmin,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, participants, isAdmin, error];
}
