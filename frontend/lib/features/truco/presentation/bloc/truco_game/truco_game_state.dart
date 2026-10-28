import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

enum TrucoGameBlocStatus {
  initial,
  loading,
  loaded,
  handConfirmed,
  gameFinished,
  error,
}

class TrucoGameState extends Equatable {
  /// How long after finishing a game its last hand can still be corrected.
  static const finishedGameEditWindow = Duration(minutes: 10);

  final TrucoGameBlocStatus status;
  final TrucoGame? game;

  /// Points entered for the current hand.
  final int entryA;
  final int entryB;

  /// Hand number being corrected; null when not editing.
  final int? editingHandNumber;
  final String? error;

  const TrucoGameState({
    this.status = TrucoGameBlocStatus.initial,
    this.game,
    this.entryA = 0,
    this.entryB = 0,
    this.editingHandNumber,
    this.error,
  });

  bool get isEditingHand => editingHandNumber != null;

  int entryOf(TrucoTeamSide side) => side == TrucoTeamSide.a ? entryA : entryB;

  /// The last closed hand when it can be reopened at [now]: it must carry
  /// the pre-hand totals, be the hand right before the current one and, on
  /// a finished game, be the finishing hand and still be inside
  /// [finishedGameEditWindow].
  TrucoHand? editableLastHandAt(DateTime now) {
    final game = this.game;
    if (game == null || game.hands.isEmpty || isEditingHand) return null;

    final last = game.hands.reduce(
      (a, b) => a.handNumber >= b.handNumber ? a : b,
    );
    if (!last.canBeEdited) return null;
    if (last.handNumber != game.currentHand - 1) return null;
    if (game.isFinished) {
      if (!last.finishedGame) return null;
      // The hand keeps its original timestamp across edits, so correcting
      // it never extends the window.
      final finishedAt = DateTime.fromMillisecondsSinceEpoch(last.timestamp);
      if (now.difference(finishedAt) > finishedGameEditWindow) return null;
    }
    return last;
  }

  TrucoGameState copyWith({
    TrucoGameBlocStatus? status,
    TrucoGame? game,
    int? entryA,
    int? entryB,
    int? editingHandNumber,
    bool clearEditingHandNumber = false,
    String? error,
    bool clearError = false,
  }) {
    return TrucoGameState(
      status: status ?? this.status,
      game: game ?? this.game,
      entryA: entryA ?? this.entryA,
      entryB: entryB ?? this.entryB,
      editingHandNumber: clearEditingHandNumber
          ? null
          : (editingHandNumber ?? this.editingHandNumber),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, game, entryA, entryB, editingHandNumber, error];
}
