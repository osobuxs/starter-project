import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';

abstract class LaLobaFirestoreDataSource {
  Future<GameEntity> createGame(String name, List<String> participantIds);
  Future<GameEntity> getGame(String gameId);

  /// Live view of a game: emits whenever the game document or any of its
  /// hands change (including local pending writes).
  Stream<GameEntity> watchGame(String gameId);
  Future<List<GameEntity>> getGameHistory();
  Future<HandEntity> createHand(
    String gameId,
    int handNumber,
    String dealerId,
    Map<String, int> scores,
  );
  Future<void> updateGameStatus(String gameId, String status);
  Future<void> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  );
  Future<void> updateGameWinner(String gameId, String winnerId);
  Future<void> addParticipantToGame(
    String gameId,
    String participantId, {
    int? insertIndex,
  });
  Future<void> updateParticipantStatsOnGameFinished(
    List<String> participantIds,
    String winnerId,
  );
  Future<List<GameEntity>> queryGamesByStatus(String status);
  Future<List<GameEntity>> queryGamesByParticipant(String participantId);
  Future<List<GameEntity>> queryGamesByWinner(String winnerId);
  Future<List<GameEntity>> queryGamesByDateRange(int startDate, int endDate);
}
