import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/remote/la_loba_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand_commit.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late LaLobaFirestoreDataSourceImpl dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = LaLobaFirestoreDataSourceImpl(firestore);
  });

  Future<void> seedGame(String gameId, List<String> participantIds) {
    return firestore.collection('games').doc(gameId).set({
      'name': 'Partida',
      'status': 'playing',
      'date': 1,
      'participantIds': participantIds,
      'currentDealerId': participantIds.first,
      'currentHand': 1,
      'participantStates': {
        for (final id in participantIds) id: {'score': 0, 'status': 'active'},
      },
      'winnerId': null,
    });
  }

  group('commitHand', () {
    test('finishing hand still commits when a participant doc is missing',
        () async {
      await seedGame('g1', ['p1', 'p2']);
      // Only p1 has a participant document; p2's is missing.
      await firestore.collection('participants').doc('p1').set({
        'name': 'Ana',
        'totalGamesPlayed': 3,
        'totalGamesWon': 1,
      });

      await dataSource.commitHand(
        const HandCommit(
          gameId: 'g1',
          hand: HandEntity(
            handNumber: 1,
            dealerId: 'p1',
            scores: {'p1': 0, 'p2': 120},
            timestamp: 10,
            finishedGame: true,
            winnerId: 'p1',
          ),
          participantIds: ['p1', 'p2'],
          participantStates: {
            'p1': {'score': 0, 'status': 'active'},
            'p2': {'score': 120, 'status': 'eliminated'},
          },
          nextDealerId: 'p2',
          nextHandNumber: 2,
          winnerId: 'p1',
        ),
      );

      final game = await firestore.collection('games').doc('g1').get();
      expect(game.data()!['status'], 'finished');
      expect(game.data()!['winnerId'], 'p1');

      final hand = await firestore
          .collection('games')
          .doc('g1')
          .collection('hands')
          .doc('1')
          .get();
      expect(hand.exists, isTrue);

      final p1 = await firestore.collection('participants').doc('p1').get();
      expect(p1.data()!['totalGamesPlayed'], 4);
      expect(p1.data()!['totalGamesWon'], 2);
      expect(p1.data()!['name'], 'Ana');

      final p2 = await firestore.collection('participants').doc('p2').get();
      expect(p2.data()!['totalGamesPlayed'], 1);
    });
  });

  group('hand rejoin scores', () {
    test('round-trips rejoinScores and reads legacy hands as null', () async {
      await seedGame('g1', ['p1', 'p2', 'p3']);
      final hands =
          firestore.collection('games').doc('g1').collection('hands');
      await hands.doc('1').set({
        'handNumber': 1,
        'dealerId': 'p1',
        'scores': {'p1': 10, 'p2': 20, 'p3': 30},
        'timestamp': 1,
      });

      await dataSource.commitHand(
        const HandCommit(
          gameId: 'g1',
          hand: HandEntity(
            handNumber: 2,
            dealerId: 'p2',
            scores: {'p1': 95, 'p2': 10, 'p3': 0},
            timestamp: 2,
            rejoinScores: {'p1': 30},
          ),
          participantIds: ['p1', 'p2', 'p3'],
          participantStates: {
            'p1': {'score': 30, 'status': 'active', 'rejoinedAtHand': 2},
            'p2': {'score': 30, 'status': 'active'},
            'p3': {'score': 30, 'status': 'active'},
          },
          nextDealerId: 'p3',
          nextHandNumber: 3,
        ),
      );

      final game = await dataSource.getGame('g1');
      expect(game.hands.map((h) => h.rejoinScores), [
        null,
        {'p1': 30},
      ]);
    });
  });

  group('addParticipantToGame', () {
    test('stores the join hand and score in the participant state without '
        'touching the previous hand', () async {
      await seedGame('g1', ['p1', 'p2']);
      final gameRef = firestore.collection('games').doc('g1');
      await gameRef.update({
        'currentHand': 3,
        'participantStates': {
          'p1': {'score': 40, 'status': 'active'},
          'p2': {'score': 70, 'status': 'active'},
        },
      });
      await gameRef.collection('hands').doc('2').set({
        'handNumber': 2,
        'dealerId': 'p1',
        'scores': {'p1': 20, 'p2': 35},
        'timestamp': 2,
      });

      await dataSource.addParticipantToGame('g1', 'p3', insertIndex: 1);

      final hand = await gameRef.collection('hands').doc('2').get();
      expect(hand.data()!['scores'], {'p1': 20, 'p2': 35});

      final game = await gameRef.get();
      expect(game.data()!['participantIds'], ['p1', 'p3', 'p2']);
      expect(game.data()!['participantStates']['p3'], {
        'score': 70,
        'status': 'active',
        'joinedAtHand': 3,
        'joinScore': 70,
      });
    });
  });

  group('getGameHistory', () {
    test('returns every game newest first with its hands', () async {
      await seedGame('old', ['p1', 'p2']);
      await seedGame('new', ['p1', 'p2']);
      await firestore.collection('games').doc('new').update({'date': 5});
      final hands =
          firestore.collection('games').doc('new').collection('hands');
      for (final number in [2, 1]) {
        await hands.doc('$number').set({
          'handNumber': number,
          'dealerId': 'p1',
          'scores': {'p1': number, 'p2': 0},
          'timestamp': number,
        });
      }

      final games = await dataSource.getGameHistory();

      expect(games.map((g) => g.id), ['new', 'old']);
      expect(games.first.hands.map((h) => h.handNumber), [1, 2]);
      expect(games.last.hands, isEmpty);
    });
  });

  group('watchGame', () {
    test('emits the game with its hands and again when a hand is added',
        () async {
      await seedGame('g1', ['p1', 'p2']);
      final hands =
          firestore.collection('games').doc('g1').collection('hands');

      final emissions = <List<int>>[];
      final subscription = dataSource.watchGame('g1').listen(
            (game) => emissions.add(
              game.hands.map((h) => h.handNumber).toList(),
            ),
          );
      await pumpEventQueue();

      await hands.doc('1').set({
        'handNumber': 1,
        'dealerId': 'p1',
        'scores': {'p1': 5, 'p2': 0},
        'timestamp': 1,
      });
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.first, isEmpty);
      expect(emissions.last, [1]);
    });
  });
}
