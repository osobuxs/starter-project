import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_game_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_state.dart';

class DardosMultiGameBloc
    extends Bloc<DardosMultiGameEvent, DardosMultiGameState> {
  final DardosGameRepository _repository;

  DardosMultiGameBloc(this._repository)
      : super(const DardosMultiGameState()) {
    on<LoadGamesEvent>(_onLoadGames);
    on<LoadGamesByModeEvent>(_onLoadGamesByMode);
    on<RefreshGamesEvent>(_onRefresh);
    on<DeleteGameEvent>(_onDeleteGame);
  }

  Future<void> _onDeleteGame(
    DeleteGameEvent event,
    Emitter<DardosMultiGameState> emit,
  ) async {
    // Defense in depth: the UI only offers delete to admins on non-finished
    // games, but re-check here. Finished games hold counted stats and must
    // be reopened (which reverts stats) before they can be removed.
    if (!event.isAdmin) return;
    DardosGameEntity? game;
    for (final g in state.games) {
      if (g.id == event.gameId) {
        game = g;
        break;
      }
    }
    if (game == null || game.status == 'finished') return;

    final result = await _repository.deleteGame(gameId: event.gameId);
    if (result is! DataSuccess) {
      emit(state.copyWith(
        status: DardosMultiGameStatus.error,
        error: result.error?.toString() ?? 'Error al eliminar la partida',
      ));
      return;
    }

    // Reload the list so the deleted game disappears.
    final reload = await _repository.getGameHistory();
    if (reload is DataSuccess) {
      emit(state.copyWith(
        status: DardosMultiGameStatus.success,
        games: reload.data ?? [],
      ));
    }
  }

  Future<void> _onLoadGames(
    LoadGamesEvent event,
    Emitter<DardosMultiGameState> emit,
  ) async {
    emit(state.copyWith(status: DardosMultiGameStatus.loading));

    final result = await _repository.getGameHistory();
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: DardosMultiGameStatus.success,
        games: result.data ?? [],
      ));
    } else {
      emit(state.copyWith(
        status: DardosMultiGameStatus.error,
        error: result.error?.toString() ?? 'Error al cargar partidas',
      ));
    }
  }

  Future<void> _onLoadGamesByMode(
    LoadGamesByModeEvent event,
    Emitter<DardosMultiGameState> emit,
  ) async {
    emit(state.copyWith(status: DardosMultiGameStatus.loading));

    final result = await _repository.queryGamesByMode(event.mode);
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: DardosMultiGameStatus.success,
        games: result.data ?? [],
      ));
    } else {
      emit(state.copyWith(
        status: DardosMultiGameStatus.error,
        error: result.error?.toString() ?? 'Error al cargar partidas por modo',
      ));
    }
  }

  Future<void> _onRefresh(
    RefreshGamesEvent event,
    Emitter<DardosMultiGameState> emit,
  ) async {
    emit(state.copyWith(status: DardosMultiGameStatus.loading));

    final result = await _repository.getGameHistory();
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: DardosMultiGameStatus.success,
        games: result.data ?? [],
      ));
    } else {
      emit(state.copyWith(
        status: DardosMultiGameStatus.error,
        error: result.error?.toString() ?? 'Error al refrescar partidas',
      ));
    }
  }
}
