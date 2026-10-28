import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_game_repository.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_dealer_rules.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_score_rules.dart';

import 'truco_game_event.dart';
import 'truco_game_state.dart';

/// Internal event fed by the realtime game subscription.
class _RemoteTrucoGameUpdatedEvent extends TrucoGameEvent {
  final DataState<TrucoGame> result;

  const _RemoteTrucoGameUpdatedEvent(this.result);

  @override
  List<Object?> get props => [result];
}

/// Internal event raised when a background hand commit fails.
class _TrucoHandCommitFailedEvent extends TrucoGameEvent {
  final String message;

  const _TrucoHandCommitFailedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class TrucoGameBloc extends Bloc<TrucoGameEvent, TrucoGameState> {
  final TrucoGameRepository _repository;
  final DateTime Function() _now;

  StreamSubscription<DataState<TrucoGame>>? _gameSubscription;

  /// Latest remote game received while editing; applied afterwards.
  TrucoGame? _bufferedRemoteGame;

  /// Board shown before entering edit mode, restored on cancel.
  TrucoGame? _gameBeforeEdit;

  /// The hand being corrected, as it was originally committed.
  TrucoHand? _editingOriginalHand;

  TrucoGameBloc({
    required TrucoGameRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now,
        super(const TrucoGameState()) {
    on<LoadTrucoGameEvent>(_onLoad);
    on<SetTrucoHandPointsEvent>(_onSetPoints);
    on<ConfirmTrucoHandEvent>(_onConfirm);
    on<StartEditLastTrucoHandEvent>(_onStartEdit);
    on<CancelEditLastTrucoHandEvent>(_onCancelEdit);
    on<_RemoteTrucoGameUpdatedEvent>(_onRemoteUpdated);
    on<_TrucoHandCommitFailedEvent>(_onCommitFailed);
  }

  @override
  Future<void> close() async {
    await _gameSubscription?.cancel();
    _gameSubscription = null;
    return super.close();
  }

  Future<void> _onLoad(
    LoadTrucoGameEvent event,
    Emitter<TrucoGameState> emit,
  ) async {
    emit(state.copyWith(status: TrucoGameBlocStatus.loading));

    final result = await _repository.getGame(event.gameId);
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: TrucoGameBlocStatus.loaded,
        game: result.data,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        status: TrucoGameBlocStatus.error,
        error: result.error?.toString() ?? 'No se pudo cargar la partida',
      ));
    }

    await _gameSubscription?.cancel();
    _bufferedRemoteGame = null;
    _gameSubscription = _repository.watchGame(event.gameId).listen((result) {
      if (!isClosed) add(_RemoteTrucoGameUpdatedEvent(result));
    });
  }

  void _onRemoteUpdated(
    _RemoteTrucoGameUpdatedEvent event,
    Emitter<TrucoGameState> emit,
  ) {
    // Stream errors are transient (offline, permissions): keep the board.
    if (event.result is! DataSuccess<TrucoGame>) return;
    final remote = event.result.data;
    if (remote == null) return;

    if (state.isEditingHand) {
      _bufferedRemoteGame = remote;
      return;
    }
    _applyRemote(remote, emit);
  }

  void _applyRemote(TrucoGame remote, Emitter<TrucoGameState> emit) {
    _bufferedRemoteGame = null;
    final finishedRemotely =
        state.game?.isFinished != true && remote.isFinished;
    // Entries are deliberately untouched: the scorer may be typing.
    emit(state.copyWith(
      status: finishedRemotely
          ? TrucoGameBlocStatus.gameFinished
          : TrucoGameBlocStatus.loaded,
      game: remote,
    ));
  }

  void _onSetPoints(
    SetTrucoHandPointsEvent event,
    Emitter<TrucoGameState> emit,
  ) {
    final game = state.game;
    if (game == null || (game.isFinished && !state.isEditingHand)) return;

    // Points only go up: never negative and never past the target.
    final remaining = game.targetScore - game.scoreOf(event.side);
    final points = event.points.clamp(0, remaining < 0 ? 0 : remaining);
    emit(event.side == TrucoTeamSide.a
        ? state.copyWith(entryA: points, clearError: true)
        : state.copyWith(entryB: points, clearError: true));
  }

  void _onConfirm(
    ConfirmTrucoHandEvent event,
    Emitter<TrucoGameState> emit,
  ) {
    final game = state.game;
    if (game == null || game.isFinished) return;

    if (state.entryA == 0 && state.entryB == 0) {
      emit(state.copyWith(
        status: TrucoGameBlocStatus.error,
        error: 'Ingrese los puntos de la mano.',
      ));
      return;
    }

    final outcome = applyTrucoHand(
      scoreA: game.scoreA,
      scoreB: game.scoreB,
      pointsA: state.entryA,
      pointsB: state.entryB,
      targetScore: game.targetScore,
    );
    if (outcome.isUnresolvedTie) {
      emit(state.copyWith(
        status: TrucoGameBlocStatus.error,
        error: 'Ambos equipos llegaron a ${game.targetScore} con el mismo '
            'total. Corrija los puntos de la mano.',
      ));
      return;
    }

    final original = state.isEditingHand ? _editingOriginalHand : null;
    final winner = outcome.winner;
    // When editing, `game` already has the hand's dealer restored.
    final dealerId = game.currentDealerId;
    final nextDealerId = trucoNextSeat(game.seatingOrder, dealerId);
    // `game` is the board right before this hand (reverted when editing),
    // so its totals are the snapshot that makes the hand editable later.
    final hand = TrucoHand(
      handNumber: game.currentHand,
      pointsA: state.entryA,
      pointsB: state.entryB,
      timestamp: original?.timestamp ?? _now().millisecondsSinceEpoch,
      scoreABefore: game.scoreA,
      scoreBBefore: game.scoreB,
      finishedGame: winner != null,
      winner: winner,
      dealerId: dealerId,
    );
    final hands = [
      ...game.hands.where((h) => h.handNumber != hand.handNumber),
      hand,
    ]..sort((a, b) => a.handNumber.compareTo(b.handNumber));

    final nextGame = game.copyWith(
      scoreA: outcome.scoreA,
      scoreB: outcome.scoreB,
      currentHand: game.currentHand + 1,
      currentDealerId: nextDealerId,
      hands: hands,
      status:
          winner == null ? TrucoGameStatus.playing : TrucoGameStatus.finished,
      winner: winner,
      clearWinner: winner == null,
    );

    emit(TrucoGameState(
      status: winner == null
          ? TrucoGameBlocStatus.handConfirmed
          : TrucoGameBlocStatus.gameFinished,
      game: nextGame,
    ));

    // Anything buffered predates this local write.
    _bufferedRemoteGame = null;
    _clearEditing();

    unawaited(_persist(TrucoHandCommit(
      gameId: game.id,
      hand: hand,
      teamAPlayerIds: game.teamA.playerIds,
      teamBPlayerIds: game.teamB.playerIds,
      scoreA: outcome.scoreA,
      scoreB: outcome.scoreB,
      nextHandNumber: nextGame.currentHand,
      winner: winner,
      isEdit: original != null,
      revertWinner: original?.finishedGame == true ? original?.winner : null,
      nextDealerId: nextDealerId,
    )));
  }

  Future<void> _persist(TrucoHandCommit commit) async {
    final result = await _repository.commitHand(commit);
    if (result is DataSuccess<void> || isClosed) return;
    add(_TrucoHandCommitFailedEvent(
      result.error?.toString() ?? 'Error desconocido',
    ));
  }

  void _onCommitFailed(
    _TrucoHandCommitFailedEvent event,
    Emitter<TrucoGameState> emit,
  ) {
    // Keep the local board: the realtime stream shows the server truth.
    emit(state.copyWith(
      status: TrucoGameBlocStatus.error,
      error: 'No se pudo guardar la mano: ${event.message}',
    ));
  }

  void _onStartEdit(
    StartEditLastTrucoHandEvent event,
    Emitter<TrucoGameState> emit,
  ) {
    final game = state.game;
    final hand = state.editableLastHandAt(_now());
    if (game == null || hand == null) return;

    _gameBeforeEdit = game;
    _editingOriginalHand = hand;

    final reverted = game.copyWith(
      scoreA: hand.scoreABefore,
      scoreB: hand.scoreBBefore,
      currentHand: hand.handNumber,
      // Legacy hands did not store their dealer: the deck moves one seat per
      // hand, so it was the seat before the current dealer.
      currentDealerId: hand.dealerId ??
          trucoPreviousSeat(game.seatingOrder, game.currentDealerId),
      hands: game.hands.where((h) => h.handNumber != hand.handNumber).toList(),
      status: TrucoGameStatus.playing,
      clearWinner: true,
    );

    emit(TrucoGameState(
      status: TrucoGameBlocStatus.loaded,
      game: reverted,
      entryA: hand.pointsA,
      entryB: hand.pointsB,
      editingHandNumber: hand.handNumber,
    ));
  }

  void _onCancelEdit(
    CancelEditLastTrucoHandEvent event,
    Emitter<TrucoGameState> emit,
  ) {
    if (!state.isEditingHand) return;

    final restored = _bufferedRemoteGame ?? _gameBeforeEdit;
    _bufferedRemoteGame = null;
    _clearEditing();

    emit(TrucoGameState(
      status: TrucoGameBlocStatus.loaded,
      game: restored ?? state.game,
    ));
  }

  void _clearEditing() {
    _gameBeforeEdit = null;
    _editingOriginalHand = null;
  }
}
