import 'dart:async';

import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_game_repository.dart';

class TrucoGameRepositoryImpl implements TrucoGameRepository {
  final TrucoFirestoreDataSource _dataSource;

  TrucoGameRepositoryImpl(this._dataSource);

  @override
  Future<DataState<TrucoGame>> createGame({
    required TrucoMode mode,
    required int targetScore,
    required TrucoTeam teamA,
    required TrucoTeam teamB,
  }) {
    return _guard(() => _dataSource.createGame(
          mode: mode,
          targetScore: targetScore,
          teamA: teamA,
          teamB: teamB,
        ));
  }

  @override
  Future<DataState<TrucoGame>> getGame(String gameId) {
    return _guard(() => _dataSource.getGame(gameId));
  }

  @override
  Stream<DataState<TrucoGame>> watchGame(String gameId) {
    return _dataSource.watchGame(gameId).transform(
          StreamTransformer<TrucoGame, DataState<TrucoGame>>.fromHandlers(
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
  Future<DataState<List<TrucoGame>>> getGames() {
    return _guard(_dataSource.getGames);
  }

  @override
  Future<DataState<void>> commitHand(TrucoHandCommit commit) {
    return _guard(() => _dataSource.commitHand(commit));
  }

  Future<DataState<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return DataSuccess(await action());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
