import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game_over_result.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class CheckGameOverUseCase {
  final GameRepository _repository;

  CheckGameOverUseCase(this._repository);

  /// Checks if the game is over after a partida finishes.
  /// Returns GameOverResult with retry candidates, auto-eliminated, and winner.
  Future<DataState<GameOverResult>> call(int gameId) async {
    final playersResult = await _repository.getActivePlayers(gameId);
    if (playersResult is DataFailed) {
      return DataFailed(playersResult.error!);
    }

    final activePlayers =
        (playersResult as DataSuccess<List<PlayerEntity>>).data!;

    // Separate players who exceeded 100
    final overLimit = activePlayers.where((p) => p.totalScore >= 100).toList();
    final underLimit = activePlayers.where((p) => p.totalScore < 100).toList();

    if (overLimit.isEmpty) {
      // No one over 100 — game continues
      return const DataSuccess(
        GameOverResult(isGameOver: false),
      );
    }

    // Categorize: retry candidates vs auto-eliminated
    final retryCandidates = <PlayerEntity>[];
    final autoEliminated = <PlayerEntity>[];

    for (final player in overLimit) {
      if (player.hasUsedRetry) {
        autoEliminated.add(player);
      } else {
        retryCandidates.add(player);
      }
    }

    // Auto-eliminate players who already used retry
    for (final player in autoEliminated) {
      await _repository.eliminatePlayer(player.id!);
    }

    // Check if game is over (only 1 or 0 players under 100 remain after auto-eliminations)
    final remainingActive = underLimit.length + retryCandidates.length;

    if (remainingActive <= 1 && retryCandidates.isEmpty) {
      // Game over — winner is the last player under 100 (if any)
      await _repository.updateGameStatus(gameId, 'finished');
      final winner = underLimit.isNotEmpty ? underLimit.first : null;

      return DataSuccess(
        GameOverResult(
          isGameOver: true,
          autoEliminated: autoEliminated,
          winner: winner,
        ),
      );
    }

    // There are retry candidates — game not over yet, pending user decisions
    return DataSuccess(
      GameOverResult(
        isGameOver: false,
        retryCandidates: retryCandidates,
        autoEliminated: autoEliminated,
      ),
    );
  }
}
