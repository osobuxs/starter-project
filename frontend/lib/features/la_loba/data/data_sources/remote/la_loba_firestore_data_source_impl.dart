import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/remote/la_loba_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/game_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/hand_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';

class LaLobaFirestoreDataSourceImpl implements LaLobaFirestoreDataSource {
  final FirebaseFirestore _firestore;

  LaLobaFirestoreDataSourceImpl(this._firestore);

  @override
  Future<GameEntity> createGame(String name, [List<String>? participantIds]) async {
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

    final data = snapshot.data()!;
    final handsSnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('hands')
        .orderBy('handNumber')
        .get();

    final hands = handsSnapshot.docs
        .map((doc) => HandModel.fromFirestore(doc.data(), doc.id).toEntity())
        .toList();

    return GameEntity(
      id: gameId,
      name: data['name'] as String,
      status: data['status'] as String,
      date: data['date'] as int,
      participantIds: List<String>.from(data['participantIds'] as List),
      currentDealerId: data['currentDealerId'] as String,
      currentHand: data['currentHand'] as int,
      participantStates: (data['participantStates'] ?? {}) as Map<String, dynamic>,
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
  Future<HandEntity> createHand(String gameId, int handNumber, String dealerId) async {
    final handRef = _firestore
        .collection('games')
        .doc(gameId)
        .collection('hands')
        .doc(handNumber.toString());

    final hand = HandEntity(
      handNumber: handNumber,
      dealerId: dealerId,
      scores: {},
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
  Future<void> addParticipantToGame(String gameId, String participantId) async {
    final gameRef = _firestore.collection('games').doc(gameId);
    final game = await getGame(gameId);

    if (!game.participantIds.contains(participantId)) {
      final newParticipantIds = [...game.participantIds, participantId];
      final newParticipantStates = {...game.participantStates};
      final highestScore = game.participantStates.values
          .whereType<Map<String, dynamic>>()
          .map((p) => (p['score'] as int?) ?? 0)
          .fold<int>(0, (max, val) => val > max ? val : max);

      newParticipantStates[participantId] = {
        'score': highestScore,
        'status': 'active',
      };

      await gameRef.update({
        'participantIds': newParticipantIds,
        'participantStates': newParticipantStates,
      });
    }
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
  Future<List<GameEntity>> queryGamesByDateRange(int startDate, int endDate) async {
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
