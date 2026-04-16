import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game_over_result.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/add_player_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/check_game_over_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/create_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/do_retry_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_history_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/finish_partida_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/record_scores_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/reject_retry_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/start_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final CreateGameUseCase _createGame;
  final AddPlayerUseCase _addPlayer;
  final StartGameUseCase _startGame;
  final RecordScoresUseCase _recordScores;
  final FinishPartidaUseCase _finishPartida;
  final CheckGameOverUseCase _checkGameOver;
  final DoRetryUseCase _doRetry;
  final RejectRetryUseCase _rejectRetry;
  final FetchGameUseCase _fetchGame;
  final FetchGameHistoryUseCase _fetchHistory;
  final GameRepository _repository;

  GameBloc({
    required CreateGameUseCase createGame,
    required AddPlayerUseCase addPlayer,
    required StartGameUseCase startGame,
    required RecordScoresUseCase recordScores,
    required FinishPartidaUseCase finishPartida,
    required CheckGameOverUseCase checkGameOver,
    required DoRetryUseCase doRetry,
    required RejectRetryUseCase rejectRetry,
    required FetchGameUseCase fetchGame,
    required FetchGameHistoryUseCase fetchHistory,
    required GameRepository repository,
  })  : _createGame = createGame,
        _addPlayer = addPlayer,
        _startGame = startGame,
        _recordScores = recordScores,
        _finishPartida = finishPartida,
        _checkGameOver = checkGameOver,
        _doRetry = doRetry,
        _rejectRetry = rejectRetry,
        _fetchGame = fetchGame,
        _fetchHistory = fetchHistory,
        _repository = repository,
        super(const GameState()) {
    on<CreateGameEvent>(_onCreateGame);
    on<AddPlayerEvent>(_onAddPlayer);
    on<StartGameEvent>(_onStartGame);
    on<RecordScoreEvent>(_onRecordScore);
    on<FinishPartidaEvent>(_onFinishPartida);
    on<DoRetryEvent>(_onDoRetry);
    on<RejectRetryEvent>(_onRejectRetry);
    on<LoadGameEvent>(_onLoadGame);
    on<LoadHistoryEvent>(_onLoadHistory);
  }

  Future<void> _onCreateGame(
    CreateGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final result = await _createGame(event.name);
    if (result is DataSuccess<GameEntity>) {
      emit(state.copyWith(
        status: GameBlocStatus.gameCreated,
        game: result.data,
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: result.error?.toString() ?? 'Error al crear el juego',
      ));
    }
  }

  Future<void> _onAddPlayer(
    AddPlayerEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final result = await _addPlayer(event.gameId, event.playerName);
    if (result is DataSuccess<PlayerEntity>) {
      // Reload game to get updated player list
      final gameResult = await _fetchGame(event.gameId);
      if (gameResult is DataSuccess<GameEntity>) {
        emit(state.copyWith(
          status: GameBlocStatus.gameCreated,
          game: gameResult.data,
        ));
      }
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: result.error?.toString() ?? 'Error al agregar jugador',
      ));
    }
  }

  Future<void> _onStartGame(
    StartGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final result = await _startGame(event.gameId);
    if (result is DataSuccess<GameEntity>) {
      final game = result.data!;
      final currentPartida = game.partidas.isNotEmpty
          ? game.partidas.last
          : null;

      emit(state.copyWith(
        status: GameBlocStatus.playing,
        game: game,
        currentPartidaNumber: currentPartida?.partidaNumber ?? 1,
        currentPartidaId: currentPartida?.id,
        currentPartidaScores: {},
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: result.error?.toString() ?? 'Error al iniciar el juego',
      ));
    }
  }

  void _onRecordScore(
    RecordScoreEvent event,
    Emitter<GameState> emit,
  ) {
    // In-memory score recording — not persisted until finishPartida
    final updatedScores = Map<int, int>.from(state.currentPartidaScores);
    updatedScores[event.playerId] = event.points;

    emit(state.copyWith(
      status: GameBlocStatus.playing,
      currentPartidaScores: updatedScores,
    ));
  }

  Future<void> _onFinishPartida(
    FinishPartidaEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final partidaId = state.currentPartidaId;
    if (partidaId == null) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: 'No hay partida activa',
      ));
      return;
    }

    // Record scores to DB
    final recordResult = await _recordScores(
      partidaId: partidaId,
      scores: state.currentPartidaScores,
    );
    if (recordResult is DataFailed) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: recordResult.error?.toString() ?? 'Error al guardar puntajes',
      ));
      return;
    }

    // Update player totals
    final finishResult = await _finishPartida(
      gameId: event.gameId,
      partidaScores: state.currentPartidaScores,
    );
    if (finishResult is DataFailed) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: finishResult.error?.toString() ?? 'Error al finalizar partida',
      ));
      return;
    }

    // Check game over
    final gameOverResult = await _checkGameOver(event.gameId);
    if (gameOverResult is DataFailed) {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: gameOverResult.error?.toString() ?? 'Error al verificar estado',
      ));
      return;
    }

    final gameOver = (gameOverResult as DataSuccess<GameOverResult>).data!;

    // Reload game for updated state
    final gameResult = await _fetchGame(event.gameId);
    final updatedGame = gameResult is DataSuccess<GameEntity>
        ? gameResult.data
        : state.game;

    if (gameOver.isGameOver) {
      emit(state.copyWith(
        status: GameBlocStatus.gameOver,
        game: updatedGame,
        currentPartidaScores: {},
      ));
      return;
    }

    if (gameOver.hasRetryCandidates) {
      emit(state.copyWith(
        status: GameBlocStatus.retryOffered,
        game: updatedGame,
        retryCandidates: gameOver.retryCandidates,
        currentPartidaScores: {},
      ));
      return;
    }

    // Continue to next partida
    await _startNextPartida(event.gameId, updatedGame, emit);
  }

  Future<void> _onDoRetry(
    DoRetryEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    await _doRetry(event.gameId, event.playerId);

    // Remove this player from retry candidates
    final remaining = state.retryCandidates
        .where((p) => p.id != event.playerId)
        .toList();

    if (remaining.isNotEmpty) {
      // More retry candidates to process
      final gameResult = await _fetchGame(event.gameId);
      final updatedGame = gameResult is DataSuccess<GameEntity>
          ? gameResult.data
          : state.game;

      emit(state.copyWith(
        status: GameBlocStatus.retryOffered,
        game: updatedGame,
        retryCandidates: remaining,
      ));
      return;
    }

    // All retries processed — check game over again
    final gameOverResult = await _checkGameOver(event.gameId);
    if (gameOverResult is DataSuccess<GameOverResult>) {
      final gameOver = gameOverResult.data!;

      final gameResult = await _fetchGame(event.gameId);
      final updatedGame = gameResult is DataSuccess<GameEntity>
          ? gameResult.data
          : state.game;

      if (gameOver.isGameOver) {
        emit(state.copyWith(
          status: GameBlocStatus.gameOver,
          game: updatedGame,
          retryCandidates: [],
        ));
        return;
      }
    }

    // Continue to next partida
    final gameResult = await _fetchGame(event.gameId);
    final updatedGame = gameResult is DataSuccess<GameEntity>
        ? gameResult.data
        : state.game;

    await _startNextPartida(event.gameId, updatedGame, emit);
  }

  Future<void> _onRejectRetry(
    RejectRetryEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    await _rejectRetry(event.playerId);

    // Remove this player from retry candidates
    final remaining = state.retryCandidates
        .where((p) => p.id != event.playerId)
        .toList();

    if (remaining.isNotEmpty) {
      final gameResult = await _fetchGame(event.gameId);
      final updatedGame = gameResult is DataSuccess<GameEntity>
          ? gameResult.data
          : state.game;

      emit(state.copyWith(
        status: GameBlocStatus.retryOffered,
        game: updatedGame,
        retryCandidates: remaining,
      ));
      return;
    }

    // All retries processed — check game over
    final gameOverResult = await _checkGameOver(event.gameId);
    final gameResult = await _fetchGame(event.gameId);
    final updatedGame = gameResult is DataSuccess<GameEntity>
        ? gameResult.data
        : state.game;

    if (gameOverResult is DataSuccess<GameOverResult>) {
      final gameOver = gameOverResult.data!;

      if (gameOver.isGameOver) {
        emit(state.copyWith(
          status: GameBlocStatus.gameOver,
          game: updatedGame,
          retryCandidates: [],
        ));
        return;
      }

      if (gameOver.hasRetryCandidates) {
        emit(state.copyWith(
          status: GameBlocStatus.retryOffered,
          game: updatedGame,
          retryCandidates: gameOver.retryCandidates,
        ));
        return;
      }
    }

    await _startNextPartida(event.gameId, updatedGame, emit);
  }

  Future<void> _onLoadGame(
    LoadGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final result = await _fetchGame(event.gameId);
    if (result is DataSuccess<GameEntity>) {
      final game = result.data!;

      if (game.status == 'finished') {
        emit(state.copyWith(
          status: GameBlocStatus.gameOver,
          game: game,
        ));
      } else if (game.status == 'playing') {
        final currentPartida = game.partidas.isNotEmpty
            ? game.partidas.last
            : null;
        emit(state.copyWith(
          status: GameBlocStatus.playing,
          game: game,
          currentPartidaNumber: currentPartida?.partidaNumber ?? 1,
          currentPartidaId: currentPartida?.id,
          currentPartidaScores: {},
        ));
      } else {
        emit(state.copyWith(
          status: GameBlocStatus.gameCreated,
          game: game,
        ));
      }
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: result.error?.toString() ?? 'Error al cargar el juego',
      ));
    }
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(state.copyWith(status: GameBlocStatus.loading, clearError: true));

    final result = await _fetchHistory();
    if (result is DataSuccess<List<GameEntity>>) {
      emit(state.copyWith(
        status: GameBlocStatus.historyLoaded,
        games: result.data!,
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: result.error?.toString() ?? 'Error al cargar historial',
      ));
    }
  }

  Future<void> _startNextPartida(
    int gameId,
    GameEntity? currentGame,
    Emitter<GameState> emit,
  ) async {
    final nextNumber = state.currentPartidaNumber + 1;
    final partidaResult = await _repository.createPartida(gameId, nextNumber);

    if (partidaResult is DataSuccess) {
      final partida = partidaResult.data!;
      final gameResult = await _fetchGame(gameId);
      final updatedGame = gameResult is DataSuccess<GameEntity>
          ? gameResult.data
          : currentGame;

      emit(state.copyWith(
        status: GameBlocStatus.playing,
        game: updatedGame,
        currentPartidaNumber: nextNumber,
        currentPartidaId: partida.id,
        currentPartidaScores: {},
        retryCandidates: [],
      ));
    } else {
      emit(state.copyWith(
        status: GameBlocStatus.error,
        error: 'Error al crear siguiente partida',
      ));
    }
  }
}
