import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand_commit.dart';

abstract class GameRepository {
  Future<DataState<GameEntity>> createGame(String name,
      [List<String>? participantIds]);
  Future<DataState<GameEntity>> getGame(String gameId);

  /// Emits the latest game (with hands) every time it changes remotely or
  /// locally. Errors are delivered as [DataFailed] without closing the stream.
  Stream<DataState<GameEntity>> watchGame(String gameId);
  Future<DataState<List<GameEntity>>> getGameHistory();
  Future<DataState<HandEntity>> createHand(
    String gameId,
    int handNumber,
    String dealerId,
    Map<String, int> scores,
  );
  /// Persists a closed hand and the resulting game state in one atomic write.
  /// Offline writes are queued by Firestore and retried until they succeed.
  Future<DataState<void>> commitHand(HandCommit commit);
  Future<DataState<void>> updateGameStatus(String gameId, String status);
  Future<DataState<void>> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  );
  Future<DataState<void>> updateGameWinner(String gameId, String winnerId);
  Future<DataState<void>> addParticipantToGame(
    String gameId,
    String participantId, {
    int? insertIndex,
  });
  Future<DataState<void>> updateParticipantStatsOnGameFinished(
    List<String> participantIds,
    String winnerId,
  );
}
