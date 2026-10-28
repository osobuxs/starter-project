import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';

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

  /// Hand number being corrected; null when not editing.
  final int? editingHandNumber;

  const GameState({
    this.status = GameBlocStatus.initial,
    this.game,
    this.currentHandScores = const {},
    this.error,
    this.pendingRetryParticipantIds = const [],
    this.currentRetryParticipantId,
    this.retryReentryBaseScore,
    this.editingHandNumber,
  });

  bool get isEditingHand => editingHandNumber != null;

  /// How long after finishing a game its last hand can still be corrected.
  static const finishedGameEditWindow = Duration(minutes: 10);

  /// The last closed hand when it can be reopened at [now]: it must carry a
  /// pre-hand snapshot (legacy hands do not), be the hand right before the
  /// current one and, on a finished game, be the hand that finished it and
  /// still be inside [finishedGameEditWindow].
  HandEntity? editableLastHandAt(DateTime now) {
    final game = this.game;
    if (game == null || game.hands.isEmpty || isEditingHand) return null;

    final last = game.hands.reduce(
      (a, b) => a.handNumber >= b.handNumber ? a : b,
    );
    if (!last.canBeEdited) return null;
    if (last.handNumber != game.currentHand - 1) return null;
    if (game.status == 'finished') {
      if (!last.finishedGame) return null;
      // The hand keeps its original timestamp across edits, so correcting
      // it never extends the window.
      final finishedAt = DateTime.fromMillisecondsSinceEpoch(last.timestamp);
      if (now.difference(finishedAt) > finishedGameEditWindow) return null;
    }
    return last;
  }

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
    int? editingHandNumber,
    bool clearEditingHandNumber = false,
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
      editingHandNumber: clearEditingHandNumber
          ? null
          : (editingHandNumber ?? this.editingHandNumber),
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
        editingHandNumber,
      ];
}
