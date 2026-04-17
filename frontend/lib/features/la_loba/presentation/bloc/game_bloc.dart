import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository _repository;

  GameBloc({required GameRepository repository})
      : _repository = repository,
        super(const GameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<LoadGameEvent>(_onLoadGame);
    on<RecordScoreEvent>(_onRecordScore);
    on<FinishPartidaEvent>(_onFinishPartida);
  }

  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading));

    final result = await _repository.createGame(event.name);
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: GameBlocStatus.gameCreated,
        game: result.data,
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: (result as DataFailed).error?.toString() ?? 'Error creating game',
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
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: (result as DataFailed).error?.toString() ?? 'Error loading game',
      ));
    }
  }

  Future<void> _onRecordScore(
    RecordScoreEvent event,
    Emitter<GameState> emit,
  ) async {
    final updated = {...state.currentHandScores};
    updated[event.participantId] = event.points;

    emit(state.copyWith(currentHandScores: updated));
  }

  Future<void> _onFinishPartida(
    FinishPartidaEvent event,
    Emitter<GameState> emit,
  ) async {
    if (state.game == null) return;

    final game = state.game!;
    emit(state.copyWith(status: GameBlocStatus.loading));

    try {
      // Create new hand
      final nextHandNumber = game.currentHand + 1;
      await _repository.createHand(
        game.id,
        nextHandNumber,
        game.currentDealerId,
      );

      // Update participant states with scores
      final updatedParticipantStates = {...game.participantStates};
      state.currentHandScores.forEach((participantId, score) {
        if (updatedParticipantStates.containsKey(participantId)) {
          final currentState = updatedParticipantStates[participantId] as Map<String, dynamic>;
          final currentScore = (currentState['score'] as int?) ?? 0;
          currentState['score'] = currentScore + score;
        }
      });

      // Rotate dealer to next participant
      final nextDealerIndex = (game.participantIds.indexOf(game.currentDealerId) + 1) % game.participantIds.length;
      final nextDealerId = game.participantIds.isNotEmpty ? game.participantIds[nextDealerIndex] : '';

      await _repository.updateParticipantScores(
        game.id,
        nextDealerId,
        nextHandNumber,
        updatedParticipantStates,
      );

      // Reload game
      final gameResult = await _repository.getGame(game.id);
      if (gameResult is DataSuccess) {
        emit(state.copyWith(
          status: GameBlocStatus.handFinished,
          game: gameResult.data,
          currentHandScores: const {},
        ));
      } else {
        emit(state.copyWith(
          status: GameBlocStatus.error,
          error: 'Error reloading game',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: e.toString(),
      ));
    }
  }
}
