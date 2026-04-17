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

    final result =
        await _gameRepository.createGame(event.gameName, event.participantIds);
    if (result is DataSuccess<GameEntity>) {
      emit(state.copyWith(
        status: MultiGameBlocStatus.gameCreated,
        playingGames: [
          result.data!,
          ...state.playingGames,
        ],
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
      final playing = games.where((g) => g.status == 'playing').toList();
      final paused = games.where((g) => g.status == 'paused').toList();
      final finished = games.where((g) => g.status == 'finished').toList();

      emit(state.copyWith(
        status: MultiGameBlocStatus.loaded,
        playingGames: playing,
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
    final target =
        state.playingGames.where((g) => g.id == event.gameId).firstOrNull;
    if (target == null) {
      return;
    }

    final result =
        await _gameRepository.updateGameStatus(event.gameId, 'paused');
    if (result is DataSuccess<void>) {
      final updatedPlaying =
          state.playingGames.where((g) => g.id != event.gameId).toList();
      final updatedPaused = [
        target.copyWith(status: 'paused'),
        ...state.pausedGames,
      ];

      emit(state.copyWith(
        status: MultiGameBlocStatus.gamePaused,
        playingGames: updatedPlaying,
        pausedGames: updatedPaused,
      ));
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
    if (result is DataSuccess<void>) {
      final updatedGame = game.copyWith(status: 'playing');
      final updatedPaused =
          state.pausedGames.where((g) => g.id != event.gameId).toList();

      emit(state.copyWith(
        status: MultiGameBlocStatus.gameResumed,
        playingGames: [updatedGame, ...state.playingGames],
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
    if (result is DataSuccess<void>) {
      final fromPlaying =
          state.playingGames.where((g) => g.id == event.gameId).firstOrNull;
      final fromPaused =
          state.pausedGames.where((g) => g.id == event.gameId).firstOrNull;
      final source = fromPlaying ?? fromPaused;

      if (source != null) {
        final finishedGame =
            source.copyWith(status: 'finished', winnerId: event.winnerId);
        emit(state.copyWith(
          status: MultiGameBlocStatus.gameFinished,
          playingGames:
              state.playingGames.where((g) => g.id != event.gameId).toList(),
          pausedGames:
              state.pausedGames.where((g) => g.id != event.gameId).toList(),
          finishedGames: [finishedGame, ...state.finishedGames],
        ));
      }
    }
  }

  Future<void> _onSelectGame(
    SelectGameEvent event,
    Emitter<MultiGameState> emit,
  ) async {
    final game = [
      ...state.playingGames,
      ...state.pausedGames,
      ...state.finishedGames,
    ].firstWhere((g) => g.id == event.gameId);
    emit(state.copyWith(selectedGame: game));
  }
}
