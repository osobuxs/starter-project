import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/local/la_loba_local_data_source.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/partida.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final LaLobaLocalDataSource _localDataSource;

  GameRepositoryImpl(this._localDataSource);

  @override
  Future<DataState<GameEntity>> createGame(String name) async {
    try {
      final game = await _localDataSource.createGame(name);
      return DataSuccess(game);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<PlayerEntity>> addPlayer(int gameId, String name) async {
    try {
      final player = await _localDataSource.addPlayer(gameId, name);
      return DataSuccess(player);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<GameEntity>> getGame(int gameId) async {
    try {
      final game = await _localDataSource.getGame(gameId);
      return DataSuccess(game);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<GameEntity>>> getGameHistory() async {
    try {
      final games = await _localDataSource.getGameHistory();
      return DataSuccess(games);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<PlayerEntity>>> getActivePlayers(int gameId) async {
    try {
      final players = await _localDataSource.getActivePlayers(gameId);
      return DataSuccess(players);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<PlayerEntity>>> getAllPlayers(int gameId) async {
    try {
      final players = await _localDataSource.getAllPlayers(gameId);
      return DataSuccess(players);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<PartidaEntity>> createPartida(
    int gameId,
    int partidaNumber,
  ) async {
    try {
      final partida = await _localDataSource.createPartida(
        gameId,
        partidaNumber,
      );
      return DataSuccess(partida);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> recordScore(
    int playerId,
    int partidaId,
    int points,
  ) async {
    try {
      await _localDataSource.recordScore(playerId, partidaId, points);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updatePlayerScore(
    int playerId,
    int newTotalScore,
  ) async {
    try {
      await _localDataSource.updatePlayerScore(playerId, newTotalScore);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updatePlayerRetry(int playerId) async {
    try {
      await _localDataSource.updatePlayerRetry(playerId);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> eliminatePlayer(int playerId) async {
    try {
      await _localDataSource.eliminatePlayer(playerId);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateGameStatus(int gameId, String status) async {
    try {
      await _localDataSource.updateGameStatus(gameId, status);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<bool>> playerNameExists(int gameId, String name) async {
    try {
      final exists = await _localDataSource.playerNameExists(gameId, name);
      return DataSuccess(exists);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
