import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';

class MultiGameBloc extends Bloc<MultiGameEvent, MultiGameState> {
  final GameRepository _gameRepository;

  MultiGameBloc(this._gameRepository) : super(const MultiGameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<LoadGamesEvent>(_onLoadGames);
    on<PauseGameEvent>(_onPauseGame);
    on<ResumeGameEvent>(_onResumeGame);
    on<FinishGameEvent>(_onFinishGame);
    on<SelectGameEvent>(_onSelectGame);
  }

  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    emit(state.copyWith(status: MultiGameBlocStatus.loading));

    final result = await _gameRepository.createGame(event.gameName);
    if (result is DataSuccess<GameEntity>) {
      emit(state.copyWith(
        status: MultiGameBlocStatus.gameCreated,
        activeGame: result.data,
      ));
    } else {
      emit(state.copyWith(
        status: MultiGameBlocStatus.error,
        error: result.error?.toString() ?? 'Error creating game',
      ));
    }
  }

  Future<void> _onLoadGames(
    LoadGamesEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    emit(state.copyWith(status: MultiGameBlocStatus.loading));

    final result = await _gameRepository.getGameHistory();
    if (result is DataSuccess<List<GameEntity>>) {
      final games = result.data ?? [];
      final active =
          games.where((g) => g.status == 'playing').firstOrNull;
      final paused =
          games.where((g) => g.status == 'paused').toList();
      final finished =
          games.where((g) => g.status == 'finished').toList();

      emit(state.copyWith(
        status: MultiGameBlocStatus.loaded,
        activeGame: active,
        pausedGames: paused,
        finishedGames: finished,
      ));
    } else {
      emit(state.copyWith(
        status: MultiGameBlocStatus.error,
        error: result.error?.toString() ?? 'Error loading games',
      ));
    }
  }

  Future<void> _onPauseGame(
    PauseGameEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    if (state.activeGame?.id == event.gameId) {
      final result =
          await _gameRepository.updateGameStatus(event.gameId, 'paused');
      if (result is DataSuccess) {
        final updatedGame = state.activeGame!.copyWith(status: 'paused');
        emit(state.copyWith(
          status: MultiGameBlocStatus.gamePaused,
          activeGame: null,
          pausedGames: [...state.pausedGames, updatedGame],
        ));
      }
    }
  }

  Future<void> _onResumeGame(
    ResumeGameEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    final game = state.pausedGames.firstWhere(
      (g) => g.id == event.gameId,
    );

    final result =
        await _gameRepository.updateGameStatus(event.gameId, 'playing');
    if (result is DataSuccess) {
      final updatedGame = game.copyWith(status: 'playing');
      final updatedPaused =
          state.pausedGames.where((g) => g.id != event.gameId).toList();

      emit(state.copyWith(
        status: MultiGameBlocStatus.gameResumed,
        activeGame: updatedGame,
        pausedGames: updatedPaused,
      ));
    }
  }

  Future<void> _onFinishGame(
    FinishGameEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    final result =
        await _gameRepository.updateGameStatus(event.gameId, 'finished');
    if (result is DataSuccess) {
      final finishedGame =
          state.activeGame?.copyWith(status: 'finished', winnerId: event.winnerId);
      if (finishedGame != null) {
        emit(state.copyWith(
          status: MultiGameBlocStatus.gameFinished,
          activeGame: null,
          finishedGames: [...state.finishedGames, finishedGame],
        ));
      }
    }
  }

  Future<void> _onSelectGame(
    SelectGameEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    final game = state.pausedGames.firstWhere(
      (g) => g.id == event.gameId,
    );
    emit(state.copyWith(selectedGame: game));
  }
}
