import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';

abstract class GameRepository {
  Future<DataState<GameEntity>> createGame(String name, [List<String>? participantIds]);
  Future<DataState<GameEntity>> getGame(String gameId);
  Future<DataState<List<GameEntity>>> getGameHistory();
  Future<DataState<HandEntity>> createHand(String gameId, int handNumber, String dealerId);
  Future<DataState<void>> updateGameStatus(String gameId, String status);
  Future<DataState<void>> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  );
  Future<DataState<void>> updateGameWinner(String gameId, String winnerId);
}
