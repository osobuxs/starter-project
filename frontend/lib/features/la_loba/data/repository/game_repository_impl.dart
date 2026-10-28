import 'dart:async';

import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/remote/la_loba_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand_commit.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final LaLobaFirestoreDataSourceImpl _firestoreDataSource;

  GameRepositoryImpl(this._firestoreDataSource);

  @override
  Future<DataState<GameEntity>> createGame(String name,
      [List<String>? participantIds]) async {
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
  Stream<DataState<GameEntity>> watchGame(String gameId) {
    return _firestoreDataSource.watchGame(gameId).transform(
          StreamTransformer<GameEntity, DataState<GameEntity>>.fromHandlers(
            handleData: (game, sink) => sink.add(DataSuccess(game)),
            handleError: (error, stackTrace, sink) => sink.add(
              DataFailed(
                error is Exception ? error : Exception(error.toString()),
              ),
            ),
          ),
        );
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
  Future<DataState<void>> commitHand(HandCommit commit) async {
    try {
      await _firestoreDataSource.commitHand(commit);
      return const DataSuccess(null);
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
  Future<DataState<void>> addParticipantToGame(
    String gameId,
    String participantId, {
    int? insertIndex,
  }) async {
    try {
      await _firestoreDataSource.addParticipantToGame(
        gameId,
        participantId,
        insertIndex: insertIndex,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
