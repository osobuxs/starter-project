import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/services/game_round_rules.dart';

import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository _repository;

  String? _pendingGameId;
  String? _pendingNextDealerId;
  int? _pendingNextHandNumber;
  int? _pendingHandNumberToPersist;
  Map<String, dynamic>? _pendingParticipantStates;
  int? _pendingRetryReentryBaseScore;

  GameBloc({required GameRepository repository})
      : _repository = repository,
        super(const GameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<LoadGameEvent>(_onLoadGame);
    on<AddPlayerEvent>(_onAddPlayer);
    on<RecordScoreEvent>(_onRecordScore);
    on<FinishPartidaEvent>(_onFinishPartida);
    on<ResolveRetryDecisionEvent>(_onResolveRetryDecision);
  }

  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading));

    final result =
        await _repository.createGame(event.name, event.participantIds);
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: GameBlocStatus.gameCreated,
        game: result.data,
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error:
            (result as DataFailed).error?.toString() ?? 'Error creating game',
      ));
    }
  }

  Future<void> _onLoadGame(
    LoadGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading));

    final result = await _repository.getGame(event.gameId);
    if (result is DataSuccess) {
      final game = result.data!;
      emit(state.copyWith(
        status: GameBlocStatus.loaded,
        game: game,
        clearPendingRetryParticipantIds: true,
        clearCurrentRetryParticipantId: true,
        clearRetryReentryBaseScore: true,
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: (result as DataFailed).error?.toString() ?? 'Error loading game',
      ));
    }
  }

  Future<void> _onAddPlayer(
    AddPlayerEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final addResult = await _repository.addParticipantToGame(
      event.gameId,
      event.participantId,
      insertIndex: event.insertIndex,
    );

    if (addResult is! DataSuccess<void>) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: addResult.error?.toString() ?? 'Error adding participant',
      ));
      return;
    }

    final gameResult = await _repository.getGame(event.gameId);
    if (gameResult is DataSuccess) {
      emit(state.copyWith(
        status: GameBlocStatus.loaded,
        game: gameResult.data,
      ));
      return;
    }

    emit(state.copyWith(
      status: GameBlocStatus.error,
      error: gameResult.error?.toString() ?? 'Error loading game',
    ));
  }

  Future<void> _onRecordScore(
    RecordScoreEvent event,
    Emitter<GameState> emit,
  ) async {
    final game = state.game;
    if (game == null) return;

    if (game.status == 'finished') {
      return;
    }

    if (!_isActive(game.participantStates[event.participantId])) {
      return;
    }

    final updated = {...state.currentHandScores};
    updated[event.participantId] = _clampScore(event.points);

    emit(state.copyWith(currentHandScores: updated));
  }

  Future<void> _onFinishPartida(
    FinishPartidaEvent event,
    Emitter<GameState> emit,
  ) async {
    if (state.game == null) return;

    final game = state.game!;
    if (game.status == 'finished') {
      return;
    }

    emit(state.copyWith(status: GameBlocStatus.loading));

    try {
      final roundScores = buildRoundScoresForActivePlayers(
        participantIds: game.participantIds,
        participantStates: game.participantStates,
        enteredScores: state.currentHandScores,
      );

      final handNumberToPersist = game.currentHand;
      final nextHandNumber = game.currentHand + 1;
      final scoreUpdate = applyRoundScoresAndFindOverLimit(
        participantStates: game.participantStates,
        roundScores: roundScores,
      );

      final activeAtOrUnderLimitCount = countActiveParticipantsAtOrUnderLimit(
        scoreUpdate.updatedStates,
      );

      if (activeAtOrUnderLimitCount == 0) {
        emit(state.copyWith(
          status: GameBlocStatus.error,
          error:
              'No se puede cerrar la mano: todos los participantes activos superan 100 puntos.',
        ));
        return;
      }

      await _repository.createHand(
        game.id,
        handNumberToPersist,
        game.currentDealerId,
        roundScores,
      );

      if (activeAtOrUnderLimitCount == 1) {
        _markOverLimitAsEliminated(
          participantStates: scoreUpdate.updatedStates,
          overLimitParticipantIds: scoreUpdate.overLimitParticipantIds,
          handNumber: handNumberToPersist,
        );
      }

      final nextDealerId = _nextDealerId(
        participantIds: game.participantIds,
        currentDealerId: game.currentDealerId,
        participantStates: scoreUpdate.updatedStates,
      );

      _pendingGameId = game.id;
      _pendingNextDealerId = nextDealerId;
      _pendingNextHandNumber = nextHandNumber;
      _pendingHandNumberToPersist = handNumberToPersist;
      _pendingParticipantStates = scoreUpdate.updatedStates;
      _pendingRetryReentryBaseScore = _computeRetryReentryBaseScore(
        participantStates: scoreUpdate.updatedStates,
        overLimitParticipantIds: scoreUpdate.overLimitParticipantIds,
      );

      if (scoreUpdate.overLimitParticipantIds.isNotEmpty &&
          activeAtOrUnderLimitCount > 1) {
        emit(state.copyWith(
          status: GameBlocStatus.retryRequired,
          pendingRetryParticipantIds: scoreUpdate.overLimitParticipantIds,
          currentRetryParticipantId: scoreUpdate.overLimitParticipantIds.first,
          retryReentryBaseScore: _pendingRetryReentryBaseScore,
        ));
        return;
      }

      await _completeRound(emit);
    } catch (e) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onResolveRetryDecision(
    ResolveRetryDecisionEvent event,
    Emitter<GameState> emit,
  ) async {
    if (_pendingParticipantStates == null) {
      return;
    }

    final pendingIds = List<String>.from(state.pendingRetryParticipantIds);
    if (pendingIds.isEmpty) {
      return;
    }

    _pendingParticipantStates = applyRetryDecision(
      participantStates: _pendingParticipantStates!,
      participantId: event.participantId,
      rejoin: event.rejoin,
      rejoinScoreOverride: event.rejoin ? _pendingRetryReentryBaseScore : null,
    );

    if (_pendingParticipantStates != null) {
      final state = _pendingParticipantStates![event.participantId];
      if (state is Map<String, dynamic>) {
        if (event.rejoin) {
          state.remove('eliminatedAtHand');
          final hand = _pendingHandNumberToPersist;
          if (hand != null) {
            state['rejoinedAtHand'] = hand;
          }
        } else {
          final hand = _pendingHandNumberToPersist;
          if (hand != null) {
            state['eliminatedAtHand'] = hand;
          }
        }
      }
    }

    final remaining =
        pendingIds.where((id) => id != event.participantId).toList();
    if (remaining.isNotEmpty) {
      emit(state.copyWith(
        status: GameBlocStatus.retryRequired,
        pendingRetryParticipantIds: remaining,
        currentRetryParticipantId: remaining.first,
        retryReentryBaseScore: _pendingRetryReentryBaseScore,
      ));
      return;
    }

    emit(state.copyWith(
      status: GameBlocStatus.loading,
      clearPendingRetryParticipantIds: true,
      clearCurrentRetryParticipantId: true,
      clearRetryReentryBaseScore: true,
    ));

    await _completeRound(emit);
  }

  Future<void> _completeRound(Emitter<GameState> emit) async {
    final game = state.game;
    final gameId = _pendingGameId;
    final nextDealerId = _pendingNextDealerId;
    final nextHandNumber = _pendingNextHandNumber;
    final participantStates = _pendingParticipantStates;

    if (game == null ||
        gameId == null ||
        nextDealerId == null ||
        nextHandNumber == null ||
        participantStates == null) {
      return;
    }

    final winnerId = determineAutomaticWinner(participantStates);

    if (winnerId != null) {
      final winnerResult = await _repository.updateGameWinner(gameId, winnerId);
      if (winnerResult is! DataSuccess<void>) {
        emit(state.copyWith(
          status: GameBlocStatus.error,
          error: winnerResult.error?.toString() ?? 'Error finishing game',
        ));
        return;
      }

      await _repository.updateParticipantStatsOnGameFinished(
        game.participantIds,
        winnerId,
      );

      await _repository.updateParticipantScores(
        gameId,
        nextDealerId,
        nextHandNumber,
        participantStates,
      );
    } else {
      final updateResult = await _repository.updateParticipantScores(
        gameId,
        nextDealerId,
        nextHandNumber,
        participantStates,
      );
      if (updateResult is! DataSuccess<void>) {
        emit(state.copyWith(
          status: GameBlocStatus.error,
          error: updateResult.error?.toString() ?? 'Error updating scores',
        ));
        return;
      }
    }

    final gameResult = await _repository.getGame(game.id);
    if (gameResult is DataSuccess) {
      emit(state.copyWith(
        status: winnerId == null
            ? GameBlocStatus.handFinished
            : GameBlocStatus.gameFinished,
        game: gameResult.data,
        currentHandScores: const {},
        clearPendingRetryParticipantIds: true,
        clearCurrentRetryParticipantId: true,
        clearRetryReentryBaseScore: true,
      ));
      _clearPendingRound();
      return;
    }

    emit(state.copyWith(
      status: GameBlocStatus.error,
      error: 'Error reloading game',
    ));
  }

  String _nextDealerId({
    required List<String> participantIds,
    required String currentDealerId,
    required Map<String, dynamic> participantStates,
  }) {
    final activeIds = participantIds
        .where((participantId) => _isActive(participantStates[participantId]))
        .toList();

    if (activeIds.isEmpty) {
      return currentDealerId;
    }

    final currentIndex = activeIds.indexOf(currentDealerId);
    final baseIndex = currentIndex >= 0 ? currentIndex : 0;
    final nextIndex = (baseIndex + 1) % activeIds.length;
    return activeIds[nextIndex];
  }

  bool _isActive(dynamic state) {
    if (state is! Map<String, dynamic>) {
      return false;
    }

    return state['status'] == 'active';
  }

  void _markOverLimitAsEliminated({
    required Map<String, dynamic> participantStates,
    required List<String> overLimitParticipantIds,
    required int handNumber,
  }) {
    for (final participantId in overLimitParticipantIds) {
      final state = participantStates[participantId];
      if (state is! Map<String, dynamic>) {
        continue;
      }

      state['status'] = 'eliminated';
      state['eliminatedAtHand'] = handNumber;
    }
  }

  void _clearPendingRound() {
    _pendingGameId = null;
    _pendingNextDealerId = null;
    _pendingNextHandNumber = null;
    _pendingHandNumberToPersist = null;
    _pendingParticipantStates = null;
    _pendingRetryReentryBaseScore = null;
  }

  int _computeRetryReentryBaseScore({
    required Map<String, dynamic> participantStates,
    required List<String> overLimitParticipantIds,
  }) {
    final overLimitSet = overLimitParticipantIds.toSet();
    var highest = 0;
    var foundCandidate = false;

    for (final entry in participantStates.entries) {
      if (overLimitSet.contains(entry.key)) {
        continue;
      }

      final participantState = entry.value;
      if (participantState is! Map<String, dynamic>) {
        continue;
      }

      if (participantState['status'] != 'active') {
        continue;
      }

      final score = participantState['score'];
      if (score is! int) {
        continue;
      }

      foundCandidate = true;
      if (score > highest) {
        highest = score;
      }
    }

    if (foundCandidate) {
      return highest;
    }

    for (final participantState in participantStates.values) {
      if (participantState is! Map<String, dynamic>) {
        continue;
      }

      if (participantState['status'] != 'active') {
        continue;
      }

      final score = participantState['score'];
      if (score is! int) {
        continue;
      }

      if (score > highest) {
        highest = score;
      }
    }

    return highest;
  }

  int _clampScore(int value) {
    if (value > 999) return 999;
    if (value < -999) return -999;
    return value;
  }
}
