import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

enum GameBlocStatus {
  initial,
  loading,
  loaded,
  gameCreated,
  playing,
  handFinished,
  retryRequired,
  gameFinished,
  error,
}

class GameState extends Equatable {
  final GameBlocStatus status;
  final GameEntity? game;
  final Map<String, int> currentHandScores; // participantId -> points
  final String? error;
  final List<String> pendingRetryParticipantIds;
  final String? currentRetryParticipantId;
  final int? retryReentryBaseScore;

  const GameState({
    this.status = GameBlocStatus.initial,
    this.game,
    this.currentHandScores = const {},
    this.error,
    this.pendingRetryParticipantIds = const [],
    this.currentRetryParticipantId,
    this.retryReentryBaseScore,
  });

  GameState copyWith({
    GameBlocStatus? status,
    GameEntity? game,
    bool clearGame = false,
    Map<String, int>? currentHandScores,
    String? error,
    bool clearError = false,
    List<String>? pendingRetryParticipantIds,
    bool clearPendingRetryParticipantIds = false,
    String? currentRetryParticipantId,
    bool clearCurrentRetryParticipantId = false,
    int? retryReentryBaseScore,
    bool clearRetryReentryBaseScore = false,
  }) {
    return GameState(
      status: status ?? this.status,
      game: clearGame ? null : (game ?? this.game),
      currentHandScores: currentHandScores ?? this.currentHandScores,
      error: clearError ? null : (error ?? this.error),
      pendingRetryParticipantIds: clearPendingRetryParticipantIds
          ? const []
          : (pendingRetryParticipantIds ?? this.pendingRetryParticipantIds),
      currentRetryParticipantId: clearCurrentRetryParticipantId
          ? null
          : (currentRetryParticipantId ?? this.currentRetryParticipantId),
      retryReentryBaseScore: clearRetryReentryBaseScore
          ? null
          : (retryReentryBaseScore ?? this.retryReentryBaseScore),
    );
  }

  @override
  List<Object?> get props => [
        status,
        game,
        currentHandScores,
        error,
        pendingRetryParticipantIds,
        currentRetryParticipantId,
        retryReentryBaseScore,
      ];
}
