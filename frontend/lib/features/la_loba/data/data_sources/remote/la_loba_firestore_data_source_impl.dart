import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/remote/la_loba_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/hand_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand_commit.dart';

class LaLobaFirestoreDataSourceImpl implements LaLobaFirestoreDataSource {
  final FirebaseFirestore _firestore;

  LaLobaFirestoreDataSourceImpl(this._firestore);

  @override
  Future<GameEntity> createGame(String name,
      [List<String>? participantIds]) async {
    final gameRef = _firestore.collection('games').doc();
    participantIds ??= [];
    final game = GameEntity(
      id: gameRef.id,
      name: name,
      status: 'playing',
      date: DateTime.now().millisecondsSinceEpoch,
      participantIds: participantIds,
      currentDealerId: participantIds.isNotEmpty ? participantIds[0] : '',
      currentHand: 1,
      participantStates: {
        for (final pid in participantIds) pid: {'score': 0, 'status': 'active'},
      },
    );

    await gameRef.set({
      'name': game.name,
      'status': game.status,
      'date': game.date,
      'participantIds': game.participantIds,
      'currentDealerId': game.currentDealerId,
      'currentHand': game.currentHand,
      'participantStates': game.participantStates,
      'winnerId': null,
    });

    return game;
  }

  @override
  Future<GameEntity> getGame(String gameId) async {
    final snapshot = await _firestore.collection('games').doc(gameId).get();

    if (!snapshot.exists) {
      throw Exception('Game not found');
    }

    final handsSnapshot = await _handsQuery(gameId).get();

    return _gameFromData(gameId, snapshot.data()!, _handsFrom(handsSnapshot));
  }

  @override
  Stream<GameEntity> watchGame(String gameId) {
    // Combines the game document and its hands subcollection into a single
    // stream. Emits only once both listeners delivered their first snapshot,
    // then on every change of either side.
    late final StreamController<GameEntity> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? gameSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? handsSub;
    Map<String, dynamic>? latestGameData;
    List<HandEntity>? latestHands;

    void emitIfReady() {
      final data = latestGameData;
      final hands = latestHands;
      if (data == null || hands == null || controller.isClosed) return;
      try {
        controller.add(_gameFromData(gameId, data, hands));
      } catch (e, st) {
        controller.addError(e, st);
      }
    }

    controller = StreamController<GameEntity>(
      onListen: () {
        gameSub = _firestore.collection('games').doc(gameId).snapshots().listen(
          (snapshot) {
            if (!snapshot.exists) {
              controller.addError(Exception('Game not found'));
              return;
            }
            latestGameData = snapshot.data();
            emitIfReady();
          },
          onError: controller.addError,
        );
        handsSub = _handsQuery(gameId).snapshots().listen(
          (snapshot) {
            latestHands = _handsFrom(snapshot);
            emitIfReady();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await gameSub?.cancel();
        await handsSub?.cancel();
      },
    );

    return controller.stream;
  }

  Query<Map<String, dynamic>> _handsQuery(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('hands')
        .orderBy('handNumber');
  }

  List<HandEntity> _handsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => HandModel.fromFirestore(doc.data(), doc.id).toEntity())
        .toList();
  }

  GameEntity _gameFromData(
    String gameId,
    Map<String, dynamic> data,
    List<HandEntity> hands,
  ) {
    return GameEntity(
      id: gameId,
      name: data['name'] as String,
      status: data['status'] as String,
      date: data['date'] as int,
      participantIds: List<String>.from(data['participantIds'] as List),
      currentDealerId: data['currentDealerId'] as String,
      currentHand: data['currentHand'] as int,
      participantStates:
          (data['participantStates'] ?? {}) as Map<String, dynamic>,
      winnerId: data['winnerId'] as String?,
      hands: hands,
    );
  }

  @override
  Future<List<GameEntity>> getGameHistory() async {
    final snapshot = await _firestore
        .collection('games')
        .orderBy('date', descending: true)
        .get();

    return Future.wait(
      snapshot.docs.map((doc) async => getGame(doc.id)),
    );
  }

  @override
  Future<HandEntity> createHand(
    String gameId,
    int handNumber,
    String dealerId,
    Map<String, int> scores,
  ) async {
    final handRef = _firestore
        .collection('games')
        .doc(gameId)
        .collection('hands')
        .doc(handNumber.toString());

    final hand = HandEntity(
      handNumber: handNumber,
      dealerId: dealerId,
      scores: scores,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await handRef.set({
      'handNumber': hand.handNumber,
      'dealerId': hand.dealerId,
      'scores': hand.scores,
      'timestamp': hand.timestamp,
    });

    return hand;
  }

  @override
  Future<void> commitHand(HandCommit commit) async {
    final gameRef = _firestore.collection('games').doc(commit.gameId);
    final handRef =
        gameRef.collection('hands').doc(commit.hand.handNumber.toString());
    final batch = _firestore.batch();

    batch.set(handRef, HandModel.fromEntity(commit.hand).toJson());

    final gameUpdate = <String, dynamic>{
      'currentDealerId': commit.nextDealerId,
      'currentHand': commit.nextHandNumber,
      'participantStates': commit.participantStates,
    };
    final winnerId = commit.winnerId;
    if (winnerId != null) {
      gameUpdate['winnerId'] = winnerId;
      gameUpdate['status'] = 'finished';
    } else if (commit.isEdit) {
      // The corrected hand no longer finishes the game.
      gameUpdate['winnerId'] = null;
      gameUpdate['status'] = 'playing';
    }
    batch.update(gameRef, gameUpdate);

    _addStatsDeltas(
      batch,
      participantIds: commit.participantIds,
      revertWinnerId: commit.revertWinnerId,
      winnerId: winnerId,
    );

    // Applied to the local cache right away (listeners fire immediately);
    // the returned future completes once the server acknowledges it.
    await batch.commit();
  }

  /// Undoes the stats of [revertWinnerId]'s finish (if any) and applies the
  /// ones of [winnerId]'s finish (if any), as net increments per participant.
  void _addStatsDeltas(
    WriteBatch batch, {
    required List<String> participantIds,
    required String? revertWinnerId,
    required String? winnerId,
  }) {
    final playedDelta =
        (winnerId != null ? 1 : 0) - (revertWinnerId != null ? 1 : 0);

    for (final participantId in participantIds) {
      final wonDelta = (participantId == winnerId ? 1 : 0) -
          (participantId == revertWinnerId ? 1 : 0);
      if (playedDelta == 0 && wonDelta == 0) continue;

      final participantRef =
          _firestore.collection('participants').doc(participantId);
      // Merge instead of update: a missing participant doc must not make the
      // whole hand batch fail (update throws not-found).
      batch.set(
        participantRef,
        {
          if (playedDelta != 0)
            'totalGamesPlayed': FieldValue.increment(playedDelta),
          if (wonDelta != 0) 'totalGamesWon': FieldValue.increment(wonDelta),
        },
        SetOptions(merge: true),
      );
    }
  }

  @override
  Future<void> updateGameStatus(String gameId, String status) async {
    await _firestore.collection('games').doc(gameId).update({
      'status': status,
    });
  }

  @override
  Future<void> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  ) async {
    await _firestore.collection('games').doc(gameId).update({
      'currentDealerId': currentDealerId,
      'currentHand': currentHand,
      'participantStates': participantStates,
    });
  }

  @override
  Future<void> updateGameWinner(String gameId, String winnerId) async {
    await _firestore.collection('games').doc(gameId).update({
      'winnerId': winnerId,
      'status': 'finished',
    });
  }

  @override
  Future<void> addParticipantToGame(
    String gameId,
    String participantId, {
    int? insertIndex,
  }) async {
    final gameRef = _firestore.collection('games').doc(gameId);
    final game = await getGame(gameId);

    if (!game.participantIds.contains(participantId)) {
      final newParticipantIds = [...game.participantIds];
      if (insertIndex == null ||
          insertIndex < 0 ||
          insertIndex > newParticipantIds.length) {
        newParticipantIds.add(participantId);
      } else {
        newParticipantIds.insert(insertIndex, participantId);
      }
      final newParticipantStates = {...game.participantStates};
      final highestScore = game.participantStates.values
          .whereType<Map<String, dynamic>>()
          .where((state) => state['status'] == 'active')
          .map((p) => (p['score'] as int?) ?? 0)
          .fold<int>(0, (max, val) => val > max ? val : max);

      // The entry score lives in the participant state; past hands are
      // never rewritten (legacy games stored it in the previous hand).
      newParticipantStates[participantId] = {
        'score': highestScore,
        'status': 'active',
        'joinedAtHand': game.currentHand,
        'joinScore': highestScore,
      };

      await gameRef.update({
        'participantIds': newParticipantIds,
        'participantStates': newParticipantStates,
      });
    }
  }

  @override
  Future<void> updateParticipantStatsOnGameFinished(
    List<String> participantIds,
    String winnerId,
  ) async {
    if (participantIds.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final participantId in participantIds) {
      final participantRef =
          _firestore.collection('participants').doc(participantId);
      batch.update(participantRef, {
        'totalGamesPlayed': FieldValue.increment(1),
      });

      if (participantId == winnerId) {
        batch.update(participantRef, {
          'totalGamesWon': FieldValue.increment(1),
        });
      }
    }

    await batch.commit();
  }

  @override
  Future<List<GameEntity>> queryGamesByStatus(String status) async {
    final snapshot = await _firestore
        .collection('games')
        .where('status', isEqualTo: status)
        .orderBy('date', descending: true)
        .get();

    return Future.wait(
      snapshot.docs.map((doc) async => getGame(doc.id)),
    );
  }

  @override
  Future<List<GameEntity>> queryGamesByParticipant(String participantId) async {
    final snapshot = await _firestore
        .collection('games')
        .where('participantIds', arrayContains: participantId)
        .orderBy('date', descending: true)
        .get();

    return Future.wait(
      snapshot.docs.map((doc) async => getGame(doc.id)),
    );
  }

  @override
  Future<List<GameEntity>> queryGamesByWinner(String winnerId) async {
    final snapshot = await _firestore
        .collection('games')
        .where('winnerId', isEqualTo: winnerId)
        .orderBy('date', descending: true)
        .get();

    return Future.wait(
      snapshot.docs.map((doc) async => getGame(doc.id)),
    );
  }

  @override
  Future<List<GameEntity>> queryGamesByDateRange(
      int startDate, int endDate) async {
    final snapshot = await _firestore
        .collection('games')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();

    return Future.wait(
      snapshot.docs.map((doc) async => getGame(doc.id)),
    );
  }
}
