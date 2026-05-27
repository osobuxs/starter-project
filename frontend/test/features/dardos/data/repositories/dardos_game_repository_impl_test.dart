import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/dardos/data/repository/dardos_game_repository_impl.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

@GenerateNiceMocks([MockSpec<DardosFirestoreDataSource>()])
import 'dardos_game_repository_impl_test.mocks.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
DardosGameEntity makeGame({String id = 'g1', String status = 'waiting'}) {
  return DardosGameEntity(
    id: id,
    name: 'Test Game',
    mode: '501',
    doubleOut: true,
    sets: 1,
    legs: 3,
    status: status,
    createdAt: 1000,
    createdBy: 'uid',
    playerIds: const ['p1', 'p2'],
    starterOrder: const ['p1', 'p2'],
    rosterLocked: false,
    currentSet: 0,
    currentLeg: 0,
    currentTurnPlayerId: 'p1',
    currentTurnIndex: 0,
    currentDartIndex: 0,
    legWinners: const [
      [null, null, null]
    ],
    setWinners: const [null],
    isActive: true,
    throws: const [],
  );
}

DardosThrowEntity makeThrow() {
  return const DardosThrowEntity(
    id: 't1',
    playerId: 'p1',
    setIndex: 0,
    legIndex: 0,
    turnIndex: 0,
    dartIndex: 0,
    number: 20,
    multiplier: 1,
    points: 20,
    isMiss: false,
    isBust: false,
    remainingAfter: 481,
    cricketPointsScored: 0,
    timestamp: 1000,
    createdBy: 'uid',
  );
}

void main() {
  late MockDardosFirestoreDataSource mockDataSource;
  late DardosGameRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockDardosFirestoreDataSource();
    repository = DardosGameRepositoryImpl(mockDataSource);
  });

  // -----------------------------------------------------------------------
  // createGame
  // -----------------------------------------------------------------------
  group('createGame', () {
    test('happy path: returns DataSuccess with game entity', () async {
      final game = makeGame();
      when(mockDataSource.createGame(
        name: anyNamed('name'),
        mode: anyNamed('mode'),
        doubleOut: anyNamed('doubleOut'),
        sets: anyNamed('sets'),
        legs: anyNamed('legs'),
        playerIds: anyNamed('playerIds'),
        createdBy: anyNamed('createdBy'),
      )).thenAnswer((_) async => game);

      final result = await repository.createGame(
        name: 'Test',
        mode: '501',
        doubleOut: true,
        sets: 1,
        legs: 3,
        playerIds: ['p1', 'p2'],
        createdBy: 'uid',
      );

      expect(result, isA<DataSuccess<DardosGameEntity>>());
      expect(result.data!.id, 'g1');
    });

    test('error path: returns DataFailed when datasource throws', () async {
      when(mockDataSource.createGame(
        name: anyNamed('name'),
        mode: anyNamed('mode'),
        doubleOut: anyNamed('doubleOut'),
        sets: anyNamed('sets'),
        legs: anyNamed('legs'),
        playerIds: anyNamed('playerIds'),
        createdBy: anyNamed('createdBy'),
      )).thenThrow(Exception('Firestore error'));

      final result = await repository.createGame(
        name: 'Test',
        mode: '501',
        doubleOut: true,
        sets: 1,
        legs: 3,
        playerIds: ['p1', 'p2'],
        createdBy: 'uid',
      );

      expect(result, isA<DataFailed<DardosGameEntity>>());
      expect(result.error, isNotNull);
    });
  });

  // -----------------------------------------------------------------------
  // appendThrow
  // -----------------------------------------------------------------------
  group('appendThrow', () {
    test('happy path: returns DataSuccess with throw entity', () async {
      final throw_ = makeThrow();
      when(mockDataSource.appendThrow(
        gameId: anyNamed('gameId'),
        throw_: anyNamed('throw_'),
      )).thenAnswer((_) async => throw_);

      final result = await repository.appendThrow(
        gameId: 'g1',
        throw_: throw_,
      );

      expect(result, isA<DataSuccess<DardosThrowEntity>>());
      expect(result.data!.id, 't1');
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.appendThrow(
        gameId: anyNamed('gameId'),
        throw_: anyNamed('throw_'),
      )).thenThrow(Exception('Network error'));

      final result = await repository.appendThrow(
        gameId: 'g1',
        throw_: makeThrow(),
      );

      expect(result, isA<DataFailed<DardosThrowEntity>>());
    });
  });

  // -----------------------------------------------------------------------
  // deleteLastThrow
  // -----------------------------------------------------------------------
  group('deleteLastThrow', () {
    test('happy path: returns DataSuccess(null)', () async {
      when(mockDataSource.deleteLastThrow(any)).thenAnswer((_) async {});

      final result = await repository.deleteLastThrow('g1');

      expect(result, isA<DataSuccess<void>>());
      verify(mockDataSource.deleteLastThrow('g1')).called(1);
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.deleteLastThrow(any))
          .thenThrow(Exception('Delete error'));

      final result = await repository.deleteLastThrow('g1');

      expect(result, isA<DataFailed<void>>());
    });
  });

  // -----------------------------------------------------------------------
  // finishGame
  // -----------------------------------------------------------------------
  group('finishGame', () {
    test('happy path: calls datasource and returns DataSuccess', () async {
      when(mockDataSource.finishGame(
        gameId: anyNamed('gameId'),
        winnerId: anyNamed('winnerId'),
        computedMetrics: anyNamed('computedMetrics'),
      )).thenAnswer((_) async {});

      final result = await repository.finishGame(
        gameId: 'g1',
        winnerId: 'p1',
        computedMetrics: const {},
      );

      expect(result, isA<DataSuccess<void>>());
      verify(mockDataSource.finishGame(
        gameId: 'g1',
        winnerId: 'p1',
        computedMetrics: anyNamed('computedMetrics'),
      )).called(1);
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.finishGame(
        gameId: anyNamed('gameId'),
        winnerId: anyNamed('winnerId'),
        computedMetrics: anyNamed('computedMetrics'),
      )).thenThrow(Exception('finish error'));

      final result = await repository.finishGame(
        gameId: 'g1',
        winnerId: 'p1',
        computedMetrics: const {},
      );

      expect(result, isA<DataFailed<void>>());
    });
  });

  // -----------------------------------------------------------------------
  // cancelGame
  // -----------------------------------------------------------------------
  group('cancelGame', () {
    test('happy path: calls datasource and returns DataSuccess', () async {
      when(mockDataSource.cancelGame(
        gameId: anyNamed('gameId'),
        cancelledBy: anyNamed('cancelledBy'),
      )).thenAnswer((_) async {});

      final result = await repository.cancelGame(
        gameId: 'g1',
        cancelledBy: 'uid-admin',
      );

      expect(result, isA<DataSuccess<void>>());
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.cancelGame(
        gameId: anyNamed('gameId'),
        cancelledBy: anyNamed('cancelledBy'),
      )).thenThrow(Exception('cancel error'));

      final result = await repository.cancelGame(
        gameId: 'g1',
        cancelledBy: 'uid-admin',
      );

      expect(result, isA<DataFailed<void>>());
    });
  });
}
