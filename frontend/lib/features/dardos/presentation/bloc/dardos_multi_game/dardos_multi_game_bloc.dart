import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
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
