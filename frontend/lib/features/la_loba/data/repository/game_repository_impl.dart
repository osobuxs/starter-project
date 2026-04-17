import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/remote/la_loba_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final LaLobaFirestoreDataSourceImpl _firestoreDataSource;

  GameRepositoryImpl(this._firestoreDataSource);

  @override
  Future<DataState<GameEntity>> createGame(String name, [List<String>? participantIds]) async {
    try {
      final game = await _firestoreDataSource.createGame(name, participantIds);
      return DataSuccess(game);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<GameEntity>> getGame(String gameId) async {
    try {
      final game = await _firestoreDataSource.getGame(gameId);
      return DataSuccess(game);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<GameEntity>>> getGameHistory() async {
    try {
      final games = await _firestoreDataSource.getGameHistory();
      return DataSuccess(games);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<HandEntity>> createHand(
    String gameId,
    int handNumber,
    String dealerId,
  ) async {
    try {
      final hand = await _firestoreDataSource.createHand(
        gameId,
        handNumber,
        dealerId,
      );
      return DataSuccess(hand);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateGameStatus(String gameId, String status) async {
    try {
      await _firestoreDataSource.updateGameStatus(gameId, status);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  ) async {
    try {
      await _firestoreDataSource.updateParticipantScores(
        gameId,
        currentDealerId,
        currentHand,
        participantStates,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateGameWinner(String gameId, String winnerId) async {
    try {
      await _firestoreDataSource.updateGameWinner(gameId, winnerId);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
