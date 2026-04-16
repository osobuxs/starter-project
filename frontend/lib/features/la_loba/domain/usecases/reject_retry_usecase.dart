import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class RejectRetryUseCase {
  final GameRepository _repository;

  RejectRetryUseCase(this._repository);

  /// Eliminates a player who rejected their retry offer.
  Future<DataState<void>> call(int playerId) async {
    return _repository.eliminatePlayer(playerId);
  }
}
