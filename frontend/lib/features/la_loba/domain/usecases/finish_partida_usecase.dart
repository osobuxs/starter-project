import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class FinishPartidaUseCase {
  final GameRepository _repository;

  FinishPartidaUseCase(this._repository);

  /// Finalizes a partida by updating each active player's totalScore.
  /// [gameId] — the game.
  /// [partidaScores] — Map of playerId → points scored THIS partida.
  /// Returns updated list of ALL players for the game.
  Future<DataState<List<PlayerEntity>>> call({
    required int gameId,
    required Map<int, int> partidaScores,
  }) async {
    try {
      final playersResult = await _repository.getAllPlayers(gameId);
      if (playersResult is DataFailed) return playersResult;

      final players = (playersResult as DataSuccess<List<PlayerEntity>>).data!;

      for (final player in players) {
        if (player.isEliminated) continue;

        final partidaPoints = partidaScores[player.id] ?? 0;
        final newTotal = player.totalScore + partidaPoints;

        final updateResult = await _repository.updatePlayerScore(
          player.id!,
          newTotal,
        );
        if (updateResult is DataFailed) {
          return DataFailed(updateResult.error!);
        }
      }

      return _repository.getAllPlayers(gameId);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
