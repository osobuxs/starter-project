import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class FetchGameHistoryUseCase {
  final GameRepository _repository;

  FetchGameHistoryUseCase(this._repository);

  Future<DataState<List<GameEntity>>> call() {
    return _repository.getGameHistory();
  }
}
