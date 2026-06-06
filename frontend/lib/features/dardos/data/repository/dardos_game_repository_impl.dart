import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_game_repository.dart';

class DardosGameRepositoryImpl implements DardosGameRepository {
  final DardosFirestoreDataSource _dataSource;

  DardosGameRepositoryImpl(this._dataSource);

  @override
  Future<DataState<DardosGameEntity>> createGame({
    required String name,
    required String mode,
    required bool doubleOut,
    required int sets,
    required int legs,
    required List<String> playerIds,
    bool teamMode = false,
    List<Map<String, dynamic>> teams = const [],
    Map<String, String> playerTeamIds = const {},
    required String createdBy,
  }) async {
    try {
      final game = await _dataSource.createGame(
        name: name,
        mode: mode,
        doubleOut: doubleOut,
        sets: sets,
        legs: legs,
        playerIds: playerIds,
        teamMode: teamMode,
        teams: teams,
        playerTeamIds: playerTeamIds,
        createdBy: createdBy,
      );
      return DataSuccess(game);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<DardosGameEntity>> getGame(String gameId) async {
    try {
      final game = await _dataSource.getGame(gameId);
      return DataSuccess(game);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<DardosGameEntity>>> getGameHistory() async {
    try {
      final games = await _dataSource.getGameHistory();
      return DataSuccess(games);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<DardosGameEntity>>> queryGamesByStatus(
    String status,
  ) async {
    try {
      final games = await _dataSource.queryGamesByStatus(status);
      return DataSuccess(games);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<DardosGameEntity>>> queryGamesByMode(
    String mode,
  ) async {
    try {
      final games = await _dataSource.queryGamesByMode(mode);
      return DataSuccess(games);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<DardosThrowEntity>> appendThrow({
    required String gameId,
    required DardosThrowEntity throw_,
  }) async {
    try {
      final result = await _dataSource.appendThrow(
        gameId: gameId,
        throw_: throw_,
      );
      return DataSuccess(result);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> deleteLastThrow(String gameId) async {
    try {
      await _dataSource.deleteLastThrow(gameId);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<DardosThrowEntity>>> getThrows(String gameId) async {
    try {
      final throws = await _dataSource.getThrows(gameId);
      return DataSuccess(throws);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateGameProgress({
    required String gameId,
    required int currentSet,
    required int currentLeg,
    required String currentTurnPlayerId,
    required int currentTurnIndex,
    required int currentDartIndex,
    required List<List<String?>> legWinners,
    required List<String?> setWinners,
    required bool rosterLocked,
  }) async {
    try {
      await _dataSource.updateGameProgress(
        gameId: gameId,
        currentSet: currentSet,
        currentLeg: currentLeg,
        currentTurnPlayerId: currentTurnPlayerId,
        currentTurnIndex: currentTurnIndex,
        currentDartIndex: currentDartIndex,
        legWinners: legWinners,
        setWinners: setWinners,
        rosterLocked: rosterLocked,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> finishGame({
    required String gameId,
    required String winnerId,
    required Map<String, dynamic> computedMetrics,
  }) async {
    try {
      await _dataSource.finishGame(
        gameId: gameId,
        winnerId: winnerId,
        computedMetrics: computedMetrics,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> reopenGame({required String gameId}) async {
    try {
      await _dataSource.reopenGame(gameId: gameId);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> cancelGame({
    required String gameId,
    required String cancelledBy,
  }) async {
    try {
      await _dataSource.cancelGame(
        gameId: gameId,
        cancelledBy: cancelledBy,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<bool>> acquireAnnotator({
    required String gameId,
    required String deviceId,
  }) async {
    try {
      final result = await _dataSource.acquireAnnotator(
        gameId: gameId,
        deviceId: deviceId,
      );
      return DataSuccess(result);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> releaseAnnotator({
    required String gameId,
    required String deviceId,
  }) async {
    try {
      await _dataSource.releaseAnnotator(
        gameId: gameId,
        deviceId: deviceId,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateParticipantStatsOnGameFinished({
    required List<String> playerIds,
    required String winnerId,
    List<String> winnerPlayerIds = const [],
    required String mode,
    required Map<String, dynamic> metricsPerPlayer,
    Map<String, Map<String, int>> freqByPlayer = const {},
  }) async {
    try {
      await _dataSource.updateParticipantStatsOnGameFinished(
        playerIds: playerIds,
        winnerId: winnerId,
        winnerPlayerIds: winnerPlayerIds,
        mode: mode,
        metricsPerPlayer: metricsPerPlayer,
        freqByPlayer: freqByPlayer,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> reverseParticipantStatsOnGameFinished({
    required List<String> playerIds,
    required String winnerId,
    List<String> winnerPlayerIds = const [],
    required String mode,
    required Map<String, dynamic> metricsPerPlayer,
    Map<String, Map<String, int>> freqByPlayer = const {},
  }) async {
    try {
      await _dataSource.reverseParticipantStatsOnGameFinished(
        playerIds: playerIds,
        winnerId: winnerId,
        winnerPlayerIds: winnerPlayerIds,
        mode: mode,
        metricsPerPlayer: metricsPerPlayer,
        freqByPlayer: freqByPlayer,
      );
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
