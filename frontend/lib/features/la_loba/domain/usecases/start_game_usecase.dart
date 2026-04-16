import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class StartGameUseCase {
  final GameRepository _repository;

  StartGameUseCase(this._repository);

  Future<DataState<GameEntity>> call(int gameId) async {
    final gameResult = await _repository.getGame(gameId);
    if (gameResult is DataFailed) return gameResult;

    final game = (gameResult as DataSuccess<GameEntity>).data!;
    if (game.players.length < 2) {
      return DataFailed(
        Exception('Se necesitan al menos 2 jugadores para empezar'),
      );
    }

    await _repository.createPartida(gameId, 1);
    await _repository.updateGameStatus(gameId, 'playing');

    return _repository.getGame(gameId);
  }
}
