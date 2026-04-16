import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class CreateGameUseCase {
  final GameRepository _repository;

  CreateGameUseCase(this._repository);

  Future<DataState<GameEntity>> call(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        DataFailed(Exception('El nombre del juego no puede estar vacío')),
      );
    }
    return _repository.createGame(trimmed);
  }
}
