import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/partida.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';

abstract class GameRepository {
  Future<DataState<GameEntity>> createGame(String name);
  Future<DataState<PlayerEntity>> addPlayer(int gameId, String name);
  Future<DataState<GameEntity>> getGame(int gameId);
  Future<DataState<List<GameEntity>>> getGameHistory();
  Future<DataState<List<PlayerEntity>>> getActivePlayers(int gameId);
  Future<DataState<List<PlayerEntity>>> getAllPlayers(int gameId);
  Future<DataState<PartidaEntity>> createPartida(int gameId, int partidaNumber);
  Future<DataState<void>> recordScore(int playerId, int partidaId, int points);
  Future<DataState<void>> updatePlayerScore(int playerId, int newTotalScore);
  Future<DataState<void>> updatePlayerRetry(int playerId);
  Future<DataState<void>> eliminatePlayer(int playerId);
  Future<DataState<void>> updateGameStatus(int gameId, String status);
  Future<DataState<bool>> playerNameExists(int gameId, String name);
}
