import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

abstract class DardosGameRepository {
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
  });

  Future<DataState<DardosGameEntity>> getGame(String gameId);

  Future<DataState<List<DardosGameEntity>>> getGameHistory();

  Future<DataState<List<DardosGameEntity>>> queryGamesByStatus(String status);

  Future<DataState<List<DardosGameEntity>>> queryGamesByMode(String mode);

  Future<DataState<DardosThrowEntity>> appendThrow({
    required String gameId,
    required DardosThrowEntity throw_,
  });

  Future<DataState<void>> deleteLastThrow(String gameId);

  Future<DataState<List<DardosThrowEntity>>> getThrows(String gameId);

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
  });

  Future<DataState<void>> finishGame({
    required String gameId,
    required String winnerId,
    required Map<String, dynamic> computedMetrics,
  });

  Future<DataState<void>> reopenGame({required String gameId});

  Future<DataState<void>> cancelGame({
    required String gameId,
    required String cancelledBy,
  });

  Future<DataState<bool>> acquireAnnotator({
    required String gameId,
    required String deviceId,
  });

  Future<DataState<void>> releaseAnnotator({
    required String gameId,
    required String deviceId,
  });

  Future<DataState<void>> updateParticipantStatsOnGameFinished({
    required List<String> playerIds,
    required String winnerId,
    List<String> winnerPlayerIds = const [],
    required String mode,
    required Map<String, dynamic> metricsPerPlayer,
    Map<String, Map<String, int>> freqByPlayer,
  });

  Future<DataState<void>> reverseParticipantStatsOnGameFinished({
    required List<String> playerIds,
    required String winnerId,
    List<String> winnerPlayerIds,
    required String mode,
    required Map<String, dynamic> metricsPerPlayer,
    Map<String, Map<String, int>> freqByPlayer,
  });
}
