import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_game_repository.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_state.dart';

/// Game lists for the Iniciar and Historial tabs.
class TrucoMultiGameBloc
    extends Bloc<TrucoMultiGameEvent, TrucoMultiGameState> {
  final TrucoGameRepository _repository;

  TrucoMultiGameBloc(this._repository) : super(const TrucoMultiGameState()) {
    on<LoadTrucoGamesEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadTrucoGamesEvent event,
    Emitter<TrucoMultiGameState> emit,
  ) async {
    emit(state.copyWith(status: TrucoMultiGameStatus.loading));
    final result = await _repository.getGames();
    if (result is DataSuccess) {
      final games = result.data ?? const [];
      emit(state.copyWith(
        status: TrucoMultiGameStatus.loaded,
        playingGames: games.where((g) => !g.isFinished).toList(),
        finishedGames: games.where((g) => g.isFinished).toList(),
      ));
    } else {
      emit(state.copyWith(
        status: TrucoMultiGameStatus.error,
        error: result.error?.toString() ?? 'No se pudieron cargar las partidas',
      ));
    }
  }
}
