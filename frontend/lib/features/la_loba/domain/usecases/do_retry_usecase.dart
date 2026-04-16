import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class DoRetryUseCase {
  final GameRepository _repository;

  DoRetryUseCase(this._repository);

  /// Resets a player's score to the highest score under 100 among active players.
  /// Marks the player as having used their retry.
  Future<DataState<PlayerEntity>> call(int gameId, int playerId) async {
    final activeResult = await _repository.getActivePlayers(gameId);
    if (activeResult is DataFailed) {
      return DataFailed(activeResult.error!);
    }

    final activePlayers =
        (activeResult as DataSuccess<List<PlayerEntity>>).data!;

    // Find the highest score under 100 among OTHER active players
    final otherActive = activePlayers
        .where((p) => p.id != playerId && p.totalScore < 100)
        .toList();

    int resetScore;
    if (otherActive.isEmpty) {
      // Edge case: no other active player under 100 — reset to 0
      resetScore = 0;
    } else {
      // Reset to the score closest to 100 (highest under 100)
      otherActive.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      resetScore = otherActive.first.totalScore;
    }

    await _repository.updatePlayerScore(playerId, resetScore);
    await _repository.updatePlayerRetry(playerId);

    final gameResult = await _repository.getGame(gameId);
    if (gameResult is DataFailed) return DataFailed(gameResult.error!);

    final updatedGame = (gameResult as DataSuccess).data!;
    final updatedPlayer = updatedGame.players.firstWhere(
      (p) => p.id == playerId,
    );

    return DataSuccess(updatedPlayer);
  }
}
