import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/dardos/data/models/dardos_game_model.dart';
import 'package:news_app_clean_architecture/features/dardos/data/models/dardos_participant_model.dart';
import 'package:news_app_clean_architecture/features/dardos/data/models/dardos_throw_model.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

class DardosFirestoreDataSourceImpl implements DardosFirestoreDataSource {
  final FirebaseFirestore _firestore;

  DardosFirestoreDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection('dardos_games');

  CollectionReference<Map<String, dynamic>> get _participants =>
      _firestore.collection('dardos_participants');

  // -----------------------------------------------------------------------
  // Games
  // -----------------------------------------------------------------------
  @override
  Future<DardosGameEntity> createGame({
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
    final ref = _games.doc();
    final now = DateTime.now().millisecondsSinceEpoch;

    final legWinners = List<List<String?>>.generate(
      sets,
      (_) => List<String?>.filled(legs, null),
    );
    final setWinners = List<String?>.filled(sets, null);

    final game = DardosGameEntity(
      id: ref.id,
      name: name,
      mode: mode,
      doubleOut: mode == 'cricket' ? false : doubleOut,
      sets: sets,
      legs: legs,
      status: 'waiting',
      createdAt: now,
      createdBy: createdBy,
      playerIds: List.from(playerIds),
      starterOrder: List.from(playerIds),
      teamMode: teamMode,
      teams: teams,
      playerTeamIds: playerTeamIds,
      rosterLocked: false,
      currentSet: 0,
      currentLeg: 0,
      currentTurnPlayerId: playerIds.isNotEmpty ? playerIds[0] : '',
      currentTurnIndex: 0,
      currentDartIndex: 0,
      legWinners: legWinners,
      setWinners: setWinners,
      isActive: true,
      throws: const [],
    );

    await ref.set(DardosGameModel.fromEntity(game, []).toJson());
    return game;
  }

  @override
  Future<DardosGameEntity> getGame(String gameId) async {
    final snap = await _games.doc(gameId).get();
    if (!snap.exists) throw Exception('Game not found: $gameId');

    final throwsSnap = await _games
        .doc(gameId)
        .collection('throws')
        .orderBy('setIndex')
        .orderBy('legIndex')
        .orderBy('turnIndex')
        .orderBy('dartIndex')
        .get();

    final throws_ = throwsSnap.docs
        .map((d) => DardosThrowModel.fromFirestore(d.data(), d.id).toEntity())
        .toList();

    return DardosGameModel.fromFirestore(snap.data()!, snap.id, throws_)
        .toEntity();
  }

  @override
  Future<List<DardosGameEntity>> getGameHistory() async {
    final snap = await _games.orderBy('createdAt', descending: true).get();
    return Future.wait(snap.docs.map((d) => getGame(d.id)));
  }

  @override
  Future<List<DardosGameEntity>> queryGamesByStatus(String status) async {
    final snap = await _games
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();
    return Future.wait(snap.docs.map((d) => getGame(d.id)));
  }

  @override
  Future<List<DardosGameEntity>> queryGamesByMode(String mode) async {
    final snap = await _games
        .where('mode', isEqualTo: mode)
        .orderBy('createdAt', descending: true)
        .get();
    return Future.wait(snap.docs.map((d) => getGame(d.id)));
  }

  // -----------------------------------------------------------------------
  // Throws
  // -----------------------------------------------------------------------
  @override
  Future<DardosThrowEntity> appendThrow({
    required String gameId,
    required DardosThrowEntity throw_,
  }) async {
    final ref = _games.doc(gameId).collection('throws').doc();
    await ref.set(DardosThrowModel.fromEntity(throw_).toJson());
    return throw_.copyWith(id: ref.id);
  }

  @override
  Future<void> deleteLastThrow(String gameId) async {
    final q = await _games
        .doc(gameId)
        .collection('throws')
        .orderBy('setIndex', descending: true)
        .orderBy('legIndex', descending: true)
        .orderBy('turnIndex', descending: true)
        .orderBy('dartIndex', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return;
    await q.docs.first.reference.delete();
  }

  @override
  Future<List<DardosThrowEntity>> getThrows(String gameId) async {
    final snap = await _games
        .doc(gameId)
        .collection('throws')
        .orderBy('setIndex')
        .orderBy('legIndex')
        .orderBy('turnIndex')
        .orderBy('dartIndex')
        .get();

    return snap.docs
        .map((d) => DardosThrowModel.fromFirestore(d.data(), d.id).toEntity())
        .toList();
  }

  // -----------------------------------------------------------------------
  // Game progress
  // -----------------------------------------------------------------------
  @override
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
  }) async {
    await _games.doc(gameId).update({
      'currentSet': currentSet,
      'currentLeg': currentLeg,
      'currentTurnPlayerId': currentTurnPlayerId,
      'currentTurnIndex': currentTurnIndex,
      'currentDartIndex': currentDartIndex,
      'legWinners': {
        for (var i = 0; i < legWinners.length; i++) i.toString(): legWinners[i],
      },
      'setWinners': setWinners,
      'rosterLocked': rosterLocked,
      'status': 'in_progress',
      // Heartbeat — keeps the annotator lock alive while playing
      'activeAnnotatorAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> finishGame({
    required String gameId,
    required String winnerId,
    required Map<String, dynamic> computedMetrics,
  }) async {
    await _games.doc(gameId).update({
      'status': 'finished',
      'winnerId': winnerId,
      'computedMetrics': computedMetrics,
      'activeAnnotator': null,
      'activeAnnotatorAt': null,
    });
  }

  @override
  Future<void> cancelGame({
    required String gameId,
    required String cancelledBy,
  }) async {
    await _games.doc(gameId).update({
      'status': 'cancelled',
      'cancelledBy': cancelledBy,
      'cancelledAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // -----------------------------------------------------------------------
  // Soft-lock
  // -----------------------------------------------------------------------
  // Annotator lock TTL — after this many ms of no heartbeat,
  // any device may take over. Heartbeats are bumped on every
  // updateGameProgress (i.e. after every dart).
  static const _annotatorTtlMs = 60 * 1000;

  @override
  Future<bool> acquireAnnotator({
    required String gameId,
    required String deviceId,
  }) async {
    return _firestore.runTransaction<bool>((tx) async {
      final ref = _games.doc(gameId);
      final snap = await tx.get(ref);
      final current = snap.data()?['activeAnnotator'] as String?;
      final lastAt = snap.data()?['activeAnnotatorAt'] as int?;
      final now = DateTime.now().millisecondsSinceEpoch;

      final isStale = lastAt != null && (now - lastAt) > _annotatorTtlMs;

      if (current == null || current == deviceId || isStale) {
        tx.update(ref, {
          'activeAnnotator': deviceId,
          'activeAnnotatorAt': now,
        });
        return true;
      }
      return false;
    });
  }

  @override
  Future<void> releaseAnnotator({
    required String gameId,
    required String deviceId,
  }) async {
    await _firestore.runTransaction<void>((tx) async {
      final ref = _games.doc(gameId);
      final snap = await tx.get(ref);
      if (snap.data()?['activeAnnotator'] == deviceId) {
        tx.update(ref, {
          'activeAnnotator': null,
          'activeAnnotatorAt': null,
        });
      }
    });
  }

  // -----------------------------------------------------------------------
  // Participants
  // -----------------------------------------------------------------------
  @override
  Future<DardosParticipantEntity> createParticipant(
    DardosParticipantEntity p,
  ) async {
    final ref = _participants.doc();
    final participant = p.copyWith(id: ref.id);
    await ref.set(DardosParticipantModel.fromEntity(participant).toJson());
    return participant;
  }

  @override
  Future<void> updateParticipant(DardosParticipantEntity p) async {
    await _participants
        .doc(p.id)
        .update(DardosParticipantModel.fromEntity(p).toJson());
  }

  @override
  Future<void> deleteParticipant(String id) async {
    await _participants.doc(id).update({
      'isActive': false,
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<DardosParticipantEntity>> fetchAllParticipants() async {
    final snap = await _participants.get();
    return snap.docs
        .map((d) =>
            DardosParticipantModel.fromFirestore(d.data(), d.id).toEntity())
        .toList();
  }

  @override
  Future<DardosParticipantEntity> fetchParticipantById(String id) async {
    final snap = await _participants.doc(id).get();
    if (!snap.exists) throw Exception('Participant not found: $id');
    return DardosParticipantModel.fromFirestore(snap.data()!, snap.id)
        .toEntity();
  }

  @override
  Future<void> updateParticipantStatsOnGameFinished({
    required List<String> playerIds,
    required String winnerId,
    List<String> winnerPlayerIds = const [],
    required String mode,
    required Map<String, dynamic> metricsPerPlayer,
    Map<String, Map<String, int>> freqByPlayer = const {},
  }) async {
    if (playerIds.isEmpty) return;

    final batch = _firestore.batch();

    for (final pid in playerIds) {
      final ref = _participants.doc(pid);
      final updates = <String, dynamic>{
        'totalGamesPlayed': FieldValue.increment(1),
      };
      final isWinner = pid == winnerId || winnerPlayerIds.contains(pid);
      if (isWinner) {
        updates['totalGamesWon'] = FieldValue.increment(1);
      }
      // Per-mode aggregate counters
      final modeKey = mode;
      updates['statsByMode.$modeKey.played'] = FieldValue.increment(1);
      if (isWinner) {
        updates['statsByMode.$modeKey.won'] = FieldValue.increment(1);
      }
      // Per-mode score/turn aggregates from this game's metrics
      final pm = metricsPerPlayer[pid] as Map<String, dynamic>?;
      if (pm != null && modeKey != 'cricket') {
        // We stored avg3Dart + bestTurn per game, but for lifetime
        // aggregation we need sums. The bloc passes raw aggregates
        // under separate keys when available; otherwise derive from
        // avg3Dart × validTurns. We use the bloc-provided sums.
        final totalPts = pm['totalPoints'];
        final validTurns = pm['validTurns'];
        final count180 = pm['count180'];
        final count140 = pm['count140plus'];
        if (totalPts is num && totalPts > 0) {
          updates['statsByMode.$modeKey.totalPoints'] =
              FieldValue.increment(totalPts.toInt());
        }
        if (validTurns is num && validTurns > 0) {
          updates['statsByMode.$modeKey.validTurns'] =
              FieldValue.increment(validTurns.toInt());
        }
        if (count180 is num && count180 > 0) {
          updates['statsByMode.$modeKey.count180'] =
              FieldValue.increment(count180.toInt());
        }
        if (count140 is num && count140 > 0) {
          updates['statsByMode.$modeKey.count140plus'] =
              FieldValue.increment(count140.toInt());
        }
      }
      // Dart frequency increments — uses dotted-path for nested map update
      final freq = freqByPlayer[pid] ?? const <String, int>{};
      for (final entry in freq.entries) {
        if (entry.value <= 0) continue;
        updates['numberFreq.${entry.key}'] = FieldValue.increment(entry.value);
      }
      batch.update(ref, updates);
    }

    await batch.commit();
  }
}
