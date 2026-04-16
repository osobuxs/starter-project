import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class FetchGameUseCase {
  final GameRepository _repository;

  FetchGameUseCase(this._repository);

  Future<DataState<GameEntity>> call(int gameId) {
    return _repository.getGame(gameId);
  }
}
