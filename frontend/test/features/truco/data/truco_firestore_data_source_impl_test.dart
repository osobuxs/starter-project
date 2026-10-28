import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TrucoFirestoreDataSourceImpl dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = TrucoFirestoreDataSourceImpl(firestore, now: () => 1000);
  });

  Future<TrucoGame> createGame() {
    return dataSource.createGame(
      name: 'Truco 28/10',
      mode: TrucoMode.twoVsTwo,
      targetScore: 30,
      teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['a1', 'a2']),
      teamB: const TrucoTeam(name: 'Ellos', playerIds: ['b1', 'b2']),
      seatingOrder: const ['a1', 'b1', 'a2', 'b2'],
      firstDealerId: 'b1',
    );
  }

  TrucoHandCommit commitFor(
    TrucoGame game, {
    required int handNumber,
    required int pointsA,
    required int pointsB,
    required int scoreABefore,
    required int scoreBBefore,
    required int scoreA,
    required int scoreB,
    TrucoTeamSide? winner,
    bool isEdit = false,
    TrucoTeamSide? revertWinner,
    String? dealerId,
    String? nextDealerId,
  }) {
    return TrucoHandCommit(
      gameId: game.id,
      hand: TrucoHand(
        handNumber: handNumber,
        pointsA: pointsA,
        pointsB: pointsB,
        timestamp: 50,
        scoreABefore: scoreABefore,
        scoreBBefore: scoreBBefore,
        finishedGame: winner != null,
        winner: winner,
        dealerId: dealerId,
      ),
      teamAPlayerIds: game.teamA.playerIds,
      teamBPlayerIds: game.teamB.playerIds,
      scoreA: scoreA,
      scoreB: scoreB,
      nextHandNumber: handNumber + 1,
      winner: winner,
      isEdit: isEdit,
      revertWinner: revertWinner,
      nextDealerId: nextDealerId,
    );
  }

  test('createGame stores a playing game at zero under truco_games', () async {
    final game = await createGame();

    final doc = await firestore.collection('truco_games').doc(game.id).get();
    expect(doc.data(), {
      'name': 'Truco 28/10',
      'mode': 2,
      'targetScore': 30,
      'teamA': {
        'name': 'Nosotros',
        'playerIds': ['a1', 'a2'],
      },
      'teamB': {
        'name': 'Ellos',
        'playerIds': ['b1', 'b2'],
      },
      'playerIds': ['a1', 'a2', 'b1', 'b2'],
      'scoreA': 0,
      'scoreB': 0,
      'status': 'playing',
      'winnerTeam': null,
      'date': 1000,
      'currentHand': 1,
      'seatingOrder': ['a1', 'b1', 'a2', 'b2'],
      'currentDealerId': 'b1',
    });
    expect(game.currentHand, 1);
    expect(game.name, 'Truco 28/10');
    expect(game.currentDealerId, 'b1');
  });

  test('commitHand stores the hand dealer and moves the deck on the game',
      () async {
    final created = await createGame();
    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 1,
      pointsB: 0,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 1,
      scoreB: 0,
      dealerId: 'b1',
      nextDealerId: 'a2',
    ));

    final game = await dataSource.getGame(created.id);

    expect(game.hands.single.dealerId, 'b1');
    expect(game.currentDealerId, 'a2');
  });

  test('games saved before names and dealers get safe defaults', () async {
    await firestore.collection('truco_games').doc('old').set({
      'mode': 2,
      'targetScore': 30,
      'teamA': {
        'name': 'Nosotros',
        'playerIds': ['a1', 'a2'],
      },
      'teamB': {
        'name': 'Ellos',
        'playerIds': ['b1', 'b2'],
      },
      'status': 'playing',
      'date': 5,
      'currentHand': 2,
    });
    await firestore
        .collection('truco_games')
        .doc('old')
        .collection('hands')
        .doc('1')
        .set({'handNumber': 1, 'pointsA': 1, 'pointsB': 0});

    final game = await dataSource.getGame('old');

    expect(game.name, 'Truco');
    expect(game.seatingOrder, ['a1', 'b1', 'a2', 'b2']);
    expect(game.currentDealerId, 'a1');
    expect(game.hands.single.dealerId, isNull);
  });

  test('getGame reads the game with its hands in order', () async {
    final created = await createGame();
    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 3,
      pointsB: 1,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 3,
      scoreB: 1,
    ));

    final game = await dataSource.getGame(created.id);

    expect(game.scoreA, 3);
    expect(game.scoreB, 1);
    expect(game.currentHand, 2);
    expect(game.teamA.playerIds, ['a1', 'a2']);
    expect(game.hands.single.pointsA, 3);
    expect(game.hands.single.canBeEdited, isTrue);
  });

  test('commitHand finishing the game records winner and player stats',
      () async {
    final created = await createGame();
    await firestore
        .collection('truco_participants')
        .doc('a1')
        .set({'name': 'Ana', 'totalGamesPlayed': 2, 'totalGamesWon': 1});

    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 30,
      pointsB: 0,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 30,
      scoreB: 0,
      winner: TrucoTeamSide.a,
    ));

    final game = await dataSource.getGame(created.id);
    expect(game.isFinished, isTrue);
    expect(game.winner, TrucoTeamSide.a);

    final a1 = await firestore.collection('truco_participants').doc('a1').get();
    expect(a1.data()!['totalGamesPlayed'], 3);
    expect(a1.data()!['totalGamesWon'], 2);
    final b2 = await firestore.collection('truco_participants').doc('b2').get();
    expect(b2.data()!['totalGamesPlayed'], 1);
    expect(b2.data()!['totalGamesWon'], isNull);
  });

  test('correcting the finishing hand reverts the stats and reopens the game',
      () async {
    final created = await createGame();
    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 30,
      pointsB: 0,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 30,
      scoreB: 0,
      winner: TrucoTeamSide.a,
    ));

    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 3,
      pointsB: 0,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 3,
      scoreB: 0,
      isEdit: true,
      revertWinner: TrucoTeamSide.a,
    ));

    final game = await dataSource.getGame(created.id);
    expect(game.isFinished, isFalse);
    expect(game.winner, isNull);
    expect(game.hands.single.pointsA, 3);

    final a1 = await firestore.collection('truco_participants').doc('a1').get();
    expect(a1.data()!['totalGamesPlayed'], 0);
    expect(a1.data()!['totalGamesWon'], 0);
  });

  test('correcting the finishing hand to the other winner swaps the wins',
      () async {
    final created = await createGame();
    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 30,
      pointsB: 0,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 30,
      scoreB: 0,
      winner: TrucoTeamSide.a,
    ));

    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 0,
      pointsB: 30,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 0,
      scoreB: 30,
      winner: TrucoTeamSide.b,
      isEdit: true,
      revertWinner: TrucoTeamSide.a,
    ));

    final a1 = await firestore.collection('truco_participants').doc('a1').get();
    final b1 = await firestore.collection('truco_participants').doc('b1').get();
    expect(a1.data()!['totalGamesPlayed'], 1);
    expect(a1.data()!['totalGamesWon'], 0);
    expect(b1.data()!['totalGamesPlayed'], 1);
    expect(b1.data()!['totalGamesWon'], 1);
    final game = await dataSource.getGame(created.id);
    expect(game.winner, TrucoTeamSide.b);
  });

  test('watchGame emits again after a hand is committed', () async {
    final created = await createGame();
    final emitted = <TrucoGame>[];
    final sub = dataSource.watchGame(created.id).listen(emitted.add);
    await pumpEventQueue();

    await dataSource.commitHand(commitFor(
      created,
      handNumber: 1,
      pointsA: 2,
      pointsB: 0,
      scoreABefore: 0,
      scoreBBefore: 0,
      scoreA: 2,
      scoreB: 0,
    ));
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted.first.scoreA, 0);
    expect(emitted.last.scoreA, 2);
    expect(emitted.last.hands, hasLength(1));
  });

  test('getGames lists games newest first', () async {
    final first = await createGame();
    dataSource = TrucoFirestoreDataSourceImpl(firestore, now: () => 2000);
    final second = await createGame();

    final games = await dataSource.getGames();

    expect(games.map((g) => g.id), [second.id, first.id]);
  });

  group('participants', () {
    test('create, rename and soft delete a player', () async {
      final created = await dataSource.createParticipant('Ana');
      await dataSource.updateParticipant(created.id, name: 'Ana María');

      var all = await dataSource.fetchAllParticipants();
      expect(all.single.name, 'Ana María');

      await dataSource.deleteParticipant(created.id);
      all = await dataSource.fetchAllParticipants();
      expect(all, isEmpty);

      final doc = await firestore
          .collection('truco_participants')
          .doc(created.id)
          .get();
      expect(doc.data()!['isActive'], isFalse);
    });

    test('players are listed by name', () async {
      await dataSource.createParticipant('Zoe');
      await dataSource.createParticipant('Beto');

      final all = await dataSource.fetchAllParticipants();

      expect(all.map((p) => p.name), ['Beto', 'Zoe']);
    });
  });
}
