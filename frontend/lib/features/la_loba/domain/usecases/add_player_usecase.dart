import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class AddPlayerUseCase {
  final GameRepository _repository;

  AddPlayerUseCase(this._repository);

  Future<DataState<PlayerEntity>> call(int gameId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return DataFailed(
        Exception('El nombre del jugador no puede estar vacío'),
      );
    }

    final existsResult = await _repository.playerNameExists(gameId, trimmed);
    if (existsResult is DataSuccess<bool> && existsResult.data == true) {
      return DataFailed(
        Exception('Ya existe un jugador con el nombre "$trimmed"'),
      );
    }

    return _repository.addPlayer(gameId, trimmed);
  }
}
