import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class RecordScoresUseCase {
  final GameRepository _repository;

  RecordScoresUseCase(this._repository);

  /// Records scores for all active players in a partida.
  /// [scores] is a Map of playerId → points for this partida.
  /// [partidaId] is the ID of the current partida.
  Future<DataState<void>> call({
    required int partidaId,
    required Map<int, int> scores,
  }) async {
    try {
      for (final entry in scores.entries) {
        final recordResult = await _repository.recordScore(
          entry.key,
          partidaId,
          entry.value,
        );
        if (recordResult is DataFailed) return recordResult;
      }
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
