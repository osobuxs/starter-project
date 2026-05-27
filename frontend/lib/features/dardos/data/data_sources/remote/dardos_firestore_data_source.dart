import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

/// Abstract interface for the Dardos Firestore data source.
/// Mirrors DardosGameRepository / DardosParticipantRepository signatures
/// but works with raw entities (no DataState wrapping).
abstract class DardosFirestoreDataSource {
  // -----------------------------------------------------------------------
  // Games
  // -----------------------------------------------------------------------
  Future<DardosGameEntity> createGame({
    required String name,
    required String mode,
    required bool doubleOut,
    required int sets,
    required int legs,
    required List<String> playerIds,
    required String createdBy,
  });

  Future<DardosGameEntity> getGame(String gameId);

  Future<List<DardosGameEntity>> getGameHistory();

  Future<List<DardosGameEntity>> queryGamesByStatus(String status);

  Future<List<DardosGameEntity>> queryGamesByMode(String mode);

  // -----------------------------------------------------------------------
  // Throws
  // -----------------------------------------------------------------------
  Future<DardosThrowEntity> appendThrow({
    required String gameId,
    required DardosThrowEntity throw_,
  });

  Future<void> deleteLastThrow(String gameId);

  Future<List<DardosThrowEntity>> getThrows(String gameId);

  // -----------------------------------------------------------------------
  // Game progress
  // -----------------------------------------------------------------------
  Future<void> updateGameProgress({
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

  Future<void> finishGame({
    required String gameId,
    required String winnerId,
    required Map<String, dynamic> computedMetrics,
  });

  Future<void> cancelGame({
    required String gameId,
    required String cancelledBy,
  });

  // -----------------------------------------------------------------------
  // Soft-lock (annotator)
  // -----------------------------------------------------------------------
  Future<bool> acquireAnnotator({
    required String gameId,
    required String deviceId,
  });

  Future<void> releaseAnnotator({
    required String gameId,
    required String deviceId,
  });

  // -----------------------------------------------------------------------
  // Participants
  // -----------------------------------------------------------------------
  Future<DardosParticipantEntity> createParticipant(DardosParticipantEntity p);

  Future<void> updateParticipant(DardosParticipantEntity p);

  Future<void> deleteParticipant(String id);

  Future<List<DardosParticipantEntity>> fetchAllParticipants();

  Future<DardosParticipantEntity> fetchParticipantById(String id);

  Future<void> updateParticipantStatsOnGameFinished({
    required List<String> playerIds,
    required String winnerId,
    required String mode,
    required Map<String, dynamic> metricsPerPlayer,
    Map<String, Map<String, int>> freqByPlayer = const {},
  });
}
