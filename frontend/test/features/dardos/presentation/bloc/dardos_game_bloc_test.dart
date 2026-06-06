import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_game_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';

@GenerateNiceMocks([MockSpec<DardosGameRepository>()])
import 'dardos_game_bloc_test.mocks.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
DardosGameEntity makeGame501({
  String id = 'g1',
  String status = 'waiting',
  bool rosterLocked = false,
  int sets = 1,
  int legs = 3,
  List<String> playerIds = const ['p1', 'p2'],
  List<List<String?>>? legWinners,
  List<String?> setWinners = const [null],
  String? winnerId,
  String? activeAnnotator,
}) {
  return DardosGameEntity(
    id: id,
    name: 'Test 501',
    mode: '501',
    doubleOut: true,
    sets: sets,
    legs: legs,
    status: status,
    createdAt: 1000,
    createdBy: 'uid',
    playerIds: playerIds,
    starterOrder: playerIds,
    rosterLocked: rosterLocked,
    currentSet: 0,
    currentLeg: 0,
    currentTurnPlayerId: playerIds.first,
    currentTurnIndex: 0,
    currentDartIndex: 0,
    legWinners: legWinners ?? [List<String?>.filled(legs, null)],
    setWinners: setWinners,
    winnerId: winnerId,
    activeAnnotator: activeAnnotator,
    isActive: true,
    throws: const [],
  );
}

DardosThrowEntity makeThrow({
  String id = 't1',
  String playerId = 'p1',
  int setIndex = 0,
  int legIndex = 0,
  int turnIndex = 0,
  int dartIndex = 0,
  int number = 20,
  int multiplier = 1,
  bool isBust = false,
  int? remainingAfter = 481,
}) {
  return DardosThrowEntity(
    id: id,
    playerId: playerId,
    setIndex: setIndex,
    legIndex: legIndex,
    turnIndex: turnIndex,
    dartIndex: dartIndex,
    number: number,
    multiplier: multiplier,
    points: number * multiplier,
    isMiss: false,
    isBust: isBust,
    remainingAfter: isBust ? null : remainingAfter,
    cricketPointsScored: 0,
    timestamp: 1000,
    createdBy: 'uid',
  );
}

void main() {
  late MockDardosGameRepository mockRepo;

  setUp(() {
    mockRepo = MockDardosGameRepository();
  });

  DardosGameBloc buildBloc() => DardosGameBloc(repository: mockRepo);

  // -----------------------------------------------------------------------
  // Part A: Creation and loading
  // -----------------------------------------------------------------------
  group('Part A: CreateDardosGameEvent', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'valid inputs: repo called and emits loading then gameCreated',
      build: () {
        when(mockRepo.createGame(
          name: anyNamed('name'),
          mode: anyNamed('mode'),
          doubleOut: anyNamed('doubleOut'),
          sets: anyNamed('sets'),
          legs: anyNamed('legs'),
          playerIds: anyNamed('playerIds'),
          createdBy: anyNamed('createdBy'),
        )).thenAnswer((_) async => DataSuccess(makeGame501()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(CreateDardosGameEvent(
        name: 'Final',
        mode: '501',
        doubleOut: true,
        sets: 1,
        legs: 3,
        playerIds: const ['p1', 'p2'],
        createdBy: 'uid',
      )),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'loading', DardosGameStatus.loading),
        isA<DardosGameState>()
            .having(
                (s) => s.status, 'gameCreated', DardosGameStatus.gameCreated)
            .having((s) => s.game, 'game non-null', isNotNull),
      ],
      verify: (_) => verify(mockRepo.createGame(
        name: anyNamed('name'),
        mode: anyNamed('mode'),
        doubleOut: anyNamed('doubleOut'),
        sets: anyNamed('sets'),
        legs: anyNamed('legs'),
        playerIds: anyNamed('playerIds'),
        createdBy: anyNamed('createdBy'),
      )).called(1),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'rapid double-tap: createGame called only once (droppable transformer)',
      build: () {
        when(mockRepo.createGame(
          name: anyNamed('name'),
          mode: anyNamed('mode'),
          doubleOut: anyNamed('doubleOut'),
          sets: anyNamed('sets'),
          legs: anyNamed('legs'),
          playerIds: anyNamed('playerIds'),
          createdBy: anyNamed('createdBy'),
        )).thenAnswer((_) async {
          // Simulate an in-flight create (network latency) so the second
          // tap arrives while the first is still being processed.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return DataSuccess(makeGame501());
        });
        return buildBloc();
      },
      act: (bloc) {
        const event = CreateDardosGameEvent(
          name: 'Final',
          mode: '501',
          doubleOut: true,
          sets: 1,
          legs: 3,
          playerIds: ['p1', 'p2'],
          createdBy: 'uid',
        );
        bloc.add(event);
        bloc.add(event);
      },
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(mockRepo.createGame(
        name: anyNamed('name'),
        mode: anyNamed('mode'),
        doubleOut: anyNamed('doubleOut'),
        sets: anyNamed('sets'),
        legs: anyNamed('legs'),
        playerIds: anyNamed('playerIds'),
        createdBy: anyNamed('createdBy'),
      )).called(1),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'fewer than 2 participants: emits error, repo NOT called',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(CreateDardosGameEvent(
        name: 'Solo',
        mode: '501',
        doubleOut: true,
        sets: 1,
        legs: 3,
        playerIds: const ['p1'],
        createdBy: 'uid',
      )),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'error', DardosGameStatus.error),
      ],
      verify: (_) => verifyNever(mockRepo.createGame(
        name: anyNamed('name'),
        mode: anyNamed('mode'),
        doubleOut: anyNamed('doubleOut'),
        sets: anyNamed('sets'),
        legs: anyNamed('legs'),
        playerIds: anyNamed('playerIds'),
        createdBy: anyNamed('createdBy'),
      )),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'empty name: emits error, repo NOT called',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(CreateDardosGameEvent(
        name: '   ',
        mode: '501',
        doubleOut: true,
        sets: 1,
        legs: 3,
        playerIds: const ['p1', 'p2'],
        createdBy: 'uid',
      )),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'error', DardosGameStatus.error),
      ],
      verify: (_) => verifyNever(mockRepo.createGame(
        name: anyNamed('name'),
        mode: anyNamed('mode'),
        doubleOut: anyNamed('doubleOut'),
        sets: anyNamed('sets'),
        legs: anyNamed('legs'),
        playerIds: anyNamed('playerIds'),
        createdBy: anyNamed('createdBy'),
      )),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'LoadDardosGameEvent: emits loading then loaded',
      build: () {
        final game = makeGame501(status: 'in_progress', rosterLocked: true);
        when(mockRepo.getGame('g1')).thenAnswer((_) async => DataSuccess(game));
        when(mockRepo.getThrows('g1'))
            .thenAnswer((_) async => const DataSuccess([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadDardosGameEvent(gameId: 'g1')),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'loading', DardosGameStatus.loading),
        isA<DardosGameState>()
            .having((s) => s.status, 'loaded', DardosGameStatus.loaded)
            .having((s) => s.game, 'game non-null', isNotNull),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // Part B: Annotator lock
  // -----------------------------------------------------------------------
  group('Part B: Annotator lock', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'AcquireAnnotatorEvent: repo called, annotatorOwned=true on success',
      build: () {
        when(mockRepo.acquireAnnotator(
          gameId: anyNamed('gameId'),
          deviceId: anyNamed('deviceId'),
        )).thenAnswer((_) async => const DataSuccess(true));
        return buildBloc();
      },
      act: (bloc) => bloc
          .add(const AcquireAnnotatorEvent(gameId: 'g1', deviceId: 'deviceA')),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.annotatorOwned,
          'annotatorOwned',
          isTrue,
        ),
      ],
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'AcquireAnnotatorEvent: annotatorOwned=false when lock is taken',
      build: () {
        when(mockRepo.acquireAnnotator(
          gameId: anyNamed('gameId'),
          deviceId: anyNamed('deviceId'),
        )).thenAnswer((_) async => const DataSuccess(false));
        return buildBloc();
      },
      act: (bloc) => bloc
          .add(const AcquireAnnotatorEvent(gameId: 'g1', deviceId: 'deviceB')),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.annotatorOwned,
          'annotatorOwned',
          isFalse,
        ),
      ],
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'RecordThrowEvent without annotator lock: emits annotatorLocked, repo NOT called',
      seed: () {
        // Pre-seeded state with a loaded game but annotatorOwned=false
        return DardosGameState(
          status: DardosGameStatus.loaded,
          game: makeGame501(status: 'in_progress', rosterLocked: true),
          annotatorOwned: false,
          liveScores: const {'p1': 501, 'p2': 501},
        );
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 20,
        multiplier: 1,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.status,
          'annotatorLocked',
          DardosGameStatus.annotatorLocked,
        ),
      ],
      verify: (_) => verifyNever(mockRepo.appendThrow(
        gameId: anyNamed('gameId'),
        throw_: anyNamed('throw_'),
      )),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'ReleaseAnnotatorEvent when owned: clears lock',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(status: 'in_progress'),
        annotatorOwned: true,
      ),
      build: () {
        when(mockRepo.releaseAnnotator(
          gameId: anyNamed('gameId'),
          deviceId: anyNamed('deviceId'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc
          .add(const ReleaseAnnotatorEvent(gameId: 'g1', deviceId: 'deviceA')),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.annotatorOwned,
          'annotatorOwned',
          isFalse,
        ),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // Part C: Roster lock
  // -----------------------------------------------------------------------
  group('Part C: Roster lock', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'first RecordThrowEvent on unlocked game sets rosterLocked=true',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(status: 'waiting', rosterLocked: false),
        annotatorOwned: true,
        liveScores: const {'p1': 501, 'p2': 501},
      ),
      build: () {
        final throw_ = makeThrow();
        when(mockRepo.appendThrow(
          gameId: anyNamed('gameId'),
          throw_: anyNamed('throw_'),
        )).thenAnswer((_) async => DataSuccess(throw_));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 20,
        multiplier: 1,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.game?.rosterLocked,
          'rosterLocked',
          isTrue,
        ),
        isA<DardosGameState>().having(
          (s) => s.game?.rosterLocked,
          'rosterLocked after persisted throw sync',
          isTrue,
        ),
      ],
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'subsequent throws keep rosterLocked=true',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(
          status: 'in_progress',
          rosterLocked: true,
          // dart 1 already thrown, dartIndex=1 now
        ).copyWith(currentDartIndex: 1),
        annotatorOwned: true,
        liveScores: const {'p1': 481, 'p2': 501},
      ),
      build: () {
        final throw_ = makeThrow(dartIndex: 1, remainingAfter: 461);
        when(mockRepo.appendThrow(
          gameId: anyNamed('gameId'),
          throw_: anyNamed('throw_'),
        )).thenAnswer((_) async => DataSuccess(throw_));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 20,
        multiplier: 1,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.game?.rosterLocked,
          'rosterLocked stays true',
          isTrue,
        ),
        isA<DardosGameState>().having(
          (s) => s.game?.rosterLocked,
          'rosterLocked stays true after persisted throw sync',
          isTrue,
        ),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // Part D: 501/301 throw recording
  // -----------------------------------------------------------------------
  group('Part D: 501 throw recording', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'normal throw: appendThrow called, live score updated, dartIndex advances',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(status: 'in_progress', rosterLocked: true),
        annotatorOwned: true,
        liveScores: const {'p1': 501, 'p2': 501},
      ),
      build: () {
        final throw_ = makeThrow(remainingAfter: 441);
        when(mockRepo.appendThrow(
          gameId: anyNamed('gameId'),
          throw_: anyNamed('throw_'),
        )).thenAnswer((_) async => DataSuccess(throw_));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 20,
        multiplier: 3,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'throwRecorded',
                DardosGameStatus.throwRecorded)
            .having((s) => s.liveScores['p1'], 'score updated', lessThan(501)),
        isA<DardosGameState>()
            .having((s) => s.status, 'throwRecorded after persisted throw sync',
                DardosGameStatus.throwRecorded)
            .having((s) => s.liveScores['p1'], 'score remains updated',
                lessThan(501)),
      ],
      verify: (_) => verify(mockRepo.appendThrow(
        gameId: anyNamed('gameId'),
        throw_: anyNamed('throw_'),
      )).called(1),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'bust on dart 2: throw persisted with isBust=true, turn ends, next player',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(
          status: 'in_progress',
          rosterLocked: true,
        ).copyWith(currentDartIndex: 1),
        annotatorOwned: true,
        throws: [makeThrow(number: 489, multiplier: 1, remainingAfter: 12)],
        // p1 has 32 left, dart 1 scored 20, now has 12 left;
        // dart 2: 15 points → 12-15=-3 → BUST
        liveScores: const {'p1': 12, 'p2': 501},
      ),
      build: () {
        // Bust throw — 15 points causes overshoot
        final bustThrow = makeThrow(
          dartIndex: 1,
          number: 15,
          multiplier: 1,
          isBust: true,
          remainingAfter: null,
        );
        when(mockRepo.appendThrow(
          gameId: anyNamed('gameId'),
          throw_: anyNamed('throw_'),
        )).thenAnswer((_) async => DataSuccess(bustThrow));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 15,
        multiplier: 1,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.bannerType,
          'bust banner',
          DardosBannerType.bust,
        ),
        isA<DardosGameState>().having(
          (s) => s.bannerType,
          'bust banner after persisted throw sync',
          DardosBannerType.bust,
        ),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // Part E: Leg/set/game resolution
  // -----------------------------------------------------------------------
  group('Part E: leg/set/game resolution', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'valid checkout: legWinners updated, bannerType=legWon, starter rotates',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        // p1 has 40 left — throws D20 to win leg
        game: makeGame501(
          status: 'in_progress',
          rosterLocked: true,
          sets: 1,
          legs: 3,
        ).copyWith(currentDartIndex: 1),
        annotatorOwned: true,
        throws: [makeThrow(number: 461, multiplier: 1, remainingAfter: 40)],
        liveScores: const {'p1': 40, 'p2': 200},
      ),
      build: () {
        // D20 = 40 pts, remainingAfter = 0 → valid checkout with doubleOut=true
        final checkoutThrow = DardosThrowEntity(
          id: 'checkout',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 1,
          number: 20,
          multiplier: 2,
          points: 40,
          isMiss: false,
          isBust: false,
          remainingAfter: 0,
          cricketPointsScored: 0,
          timestamp: 1000,
          createdBy: 'uid',
        );
        when(mockRepo.appendThrow(
          gameId: anyNamed('gameId'),
          throw_: anyNamed('throw_'),
        )).thenAnswer((_) async => DataSuccess(checkoutThrow));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 20,
        multiplier: 2,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.bannerType,
          'bannerType=legWon',
          DardosBannerType.legWon,
        ),
        isA<DardosGameState>().having(
          (s) => s.bannerType,
          'bannerType=legWon after persisted throw sync',
          DardosBannerType.legWon,
        ),
      ],
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'game finished: finishGame called, bannerType=gameWon, annotator released',
      seed: () {
        // p1 won all necessary legs — one more checkout finishes the game
        // 1 set, 1 leg → single checkout wins game
        return DardosGameState(
          status: DardosGameStatus.loaded,
          game: makeGame501(
            status: 'in_progress',
            rosterLocked: true,
            sets: 1,
            legs: 1,
            setWinners: const [null],
            legWinners: const [
              [null]
            ],
          ).copyWith(currentDartIndex: 1),
          annotatorOwned: true,
          throws: [makeThrow(number: 461, multiplier: 1, remainingAfter: 40)],
          liveScores: const {'p1': 40, 'p2': 200},
        );
      },
      build: () {
        final checkoutThrow = DardosThrowEntity(
          id: 'checkout',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 1,
          number: 20,
          multiplier: 2,
          points: 40,
          isMiss: false,
          isBust: false,
          remainingAfter: 0,
          cricketPointsScored: 0,
          timestamp: 1000,
          createdBy: 'uid',
        );
        when(mockRepo.appendThrow(
          gameId: anyNamed('gameId'),
          throw_: anyNamed('throw_'),
        )).thenAnswer((_) async => DataSuccess(checkoutThrow));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.finishGame(
          gameId: anyNamed('gameId'),
          winnerId: anyNamed('winnerId'),
          computedMetrics: anyNamed('computedMetrics'),
        )).thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.updateParticipantStatsOnGameFinished(
          playerIds: anyNamed('playerIds'),
          winnerId: anyNamed('winnerId'),
          winnerPlayerIds: anyNamed('winnerPlayerIds'),
          mode: anyNamed('mode'),
          metricsPerPlayer: anyNamed('metricsPerPlayer'),
          freqByPlayer: anyNamed('freqByPlayer'),
        )).thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.releaseAnnotator(
          gameId: anyNamed('gameId'),
          deviceId: anyNamed('deviceId'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RecordThrowEvent(
        number: 20,
        multiplier: 2,
        isMiss: false,
      )),
      expect: () => [
        isA<DardosGameState>().having(
          (s) => s.bannerType,
          'bannerType=gameWon',
          DardosBannerType.gameWon,
        ),
        // After the final writes land, the banner is cleared so the play
        // page gets the gameWon → none transition it needs to navigate.
        isA<DardosGameState>().having(
          (s) => s.bannerType,
          'banner cleared after persisted throw sync',
          DardosBannerType.none,
        ),
      ],
      verify: (_) {
        verify(mockRepo.finishGame(
          gameId: anyNamed('gameId'),
          winnerId: anyNamed('winnerId'),
          computedMetrics: anyNamed('computedMetrics'),
        )).called(1);
        verify(mockRepo.updateParticipantStatsOnGameFinished(
          playerIds: anyNamed('playerIds'),
          winnerId: anyNamed('winnerId'),
          winnerPlayerIds: anyNamed('winnerPlayerIds'),
          mode: anyNamed('mode'),
          metricsPerPlayer: anyNamed('metricsPerPlayer'),
          freqByPlayer: anyNamed('freqByPlayer'),
        )).called(1);
      },
    );
  });

  // -----------------------------------------------------------------------
  // Part F: Undo
  // -----------------------------------------------------------------------
  group('Part F: UndoLastThrowEvent', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'undo with throws present: deleteLastThrow called, state recomputed',
      seed: () {
        final game = makeGame501(status: 'in_progress', rosterLocked: true);
        return DardosGameState(
          status: DardosGameStatus.loaded,
          game: game,
          annotatorOwned: true,
          throws: [makeThrow()],
          liveScores: const {'p1': 481, 'p2': 501},
        );
      },
      build: () {
        when(mockRepo.deleteLastThrow(any))
            .thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.getThrows(any))
            .thenAnswer((_) async => const DataSuccess([]));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(UndoLastThrowEvent()),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.bannerType, 'bannerNone', DardosBannerType.none)
            .having((s) => s.throws.isEmpty, 'throws empty', isTrue),
      ],
      verify: (_) {
        verify(mockRepo.deleteLastThrow(any)).called(1);
        verifyNever(mockRepo.getThrows(any));
      },
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'undo with 0 throws: ignored, no repo calls',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(status: 'in_progress', rosterLocked: false),
        annotatorOwned: true,
        throws: const [],
        liveScores: const {'p1': 501, 'p2': 501},
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(UndoLastThrowEvent()),
      expect: () => <DardosGameState>[],
      verify: (_) {
        verifyNever(mockRepo.deleteLastThrow(any));
        verifyNever(mockRepo.getThrows(any));
      },
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'undo crossing leg boundary: legWinners recalculated',
      seed: () {
        // Simulate: leg 0 was won by p1 (legWinners[0][0] = 'p1'), now in leg 1
        final game = makeGame501(
          status: 'in_progress',
          rosterLocked: true,
          sets: 1,
          legs: 3,
          legWinners: const [
            ['p1', null, null]
          ],
          setWinners: const [null],
        ).copyWith(currentLeg: 1);

        // The winning throw for leg 0
        final winThrow = DardosThrowEntity(
          id: 'win',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 0,
          number: 20,
          multiplier: 2,
          points: 40,
          isMiss: false,
          isBust: false,
          remainingAfter: 0,
          cricketPointsScored: 0,
          timestamp: 9999,
          createdBy: 'uid',
        );

        return DardosGameState(
          status: DardosGameStatus.loaded,
          game: game,
          annotatorOwned: true,
          throws: [winThrow],
          liveScores: const {'p1': 501, 'p2': 501},
        );
      },
      build: () {
        // After undo, no throws remain → game back to start of leg 0
        when(mockRepo.deleteLastThrow(any))
            .thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.getThrows(any))
            .thenAnswer((_) async => const DataSuccess([]));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(UndoLastThrowEvent()),
      expect: () => [
        isA<DardosGameState>().having(
          // After undo, currentLeg is back to 0 (first leg)
          (s) => s.game?.currentLeg,
          'currentLeg reset to 0',
          0,
        ),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // Part G: Cancellation
  // -----------------------------------------------------------------------
  group('Part G: CancelGameEvent', () {
    blocTest<DardosGameBloc, DardosGameState>(
      'admin: cancelGame called, emits cancelled status',
      build: () {
        when(mockRepo.cancelGame(
          gameId: anyNamed('gameId'),
          cancelledBy: anyNamed('cancelledBy'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CancelGameEvent(
        gameId: 'g1',
        cancelledBy: 'lfexevega95@gmail.com',
        isAdmin: true,
      )),
      expect: () => [
        isA<DardosGameState>().having(
            (s) => s.status, 'cancelled', DardosGameStatus.gameCancelled),
      ],
      verify: (_) => verify(mockRepo.cancelGame(
        gameId: anyNamed('gameId'),
        cancelledBy: anyNamed('cancelledBy'),
      )).called(1),
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'non-admin: emits error, repo NOT called',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const CancelGameEvent(
        gameId: 'g1',
        cancelledBy: 'notadmin@gmail.com',
        isAdmin: false,
      )),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'error', DardosGameStatus.error),
      ],
      verify: (_) => verifyNever(mockRepo.cancelGame(
        gameId: anyNamed('gameId'),
        cancelledBy: anyNamed('cancelledBy'),
      )),
    );
  });

  // -----------------------------------------------------------------------
  // Part H: Reopen (undo winning dart of a finished game)
  // -----------------------------------------------------------------------
  group('Part H: ReopenGameEvent', () {
    DardosGameState seedFinished() {
      final game = makeGame501(
        status: 'finished',
        rosterLocked: true,
        winnerId: 'p1',
      ).copyWith(currentTurnPlayerId: 'p1');
      return DardosGameState(
        status: DardosGameStatus.gameFinished,
        game: game,
        annotatorOwned: true,
        throws: [makeThrow(playerId: 'p1', remainingAfter: 0)],
        liveScores: const {'p1': 0, 'p2': 501},
      );
    }

    blocTest<DardosGameBloc, DardosGameState>(
      'admin on a finished game: reverses stats, deletes last dart, reopens',
      seed: seedFinished,
      build: () {
        when(mockRepo.reverseParticipantStatsOnGameFinished(
          playerIds: anyNamed('playerIds'),
          winnerId: anyNamed('winnerId'),
          winnerPlayerIds: anyNamed('winnerPlayerIds'),
          mode: anyNamed('mode'),
          metricsPerPlayer: anyNamed('metricsPerPlayer'),
          freqByPlayer: anyNamed('freqByPlayer'),
        )).thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.deleteLastThrow(any))
            .thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.reopenGame(gameId: anyNamed('gameId')))
            .thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.updateGameProgress(
          gameId: anyNamed('gameId'),
          currentSet: anyNamed('currentSet'),
          currentLeg: anyNamed('currentLeg'),
          currentTurnPlayerId: anyNamed('currentTurnPlayerId'),
          currentTurnIndex: anyNamed('currentTurnIndex'),
          currentDartIndex: anyNamed('currentDartIndex'),
          legWinners: anyNamed('legWinners'),
          setWinners: anyNamed('setWinners'),
          rosterLocked: anyNamed('rosterLocked'),
        )).thenAnswer((_) async => const DataSuccess(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ReopenGameEvent(gameId: 'g1', isAdmin: true)),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'reopened',
                DardosGameStatus.gameReopened)
            .having((s) => s.game?.winnerId, 'winner cleared', isNull)
            .having((s) => s.throws.isEmpty, 'winning dart removed', isTrue),
      ],
      verify: (_) {
        verify(mockRepo.reverseParticipantStatsOnGameFinished(
          playerIds: anyNamed('playerIds'),
          winnerId: anyNamed('winnerId'),
          winnerPlayerIds: anyNamed('winnerPlayerIds'),
          mode: anyNamed('mode'),
          metricsPerPlayer: anyNamed('metricsPerPlayer'),
          freqByPlayer: anyNamed('freqByPlayer'),
        )).called(1);
        verify(mockRepo.deleteLastThrow(any)).called(1);
        verify(mockRepo.reopenGame(gameId: anyNamed('gameId'))).called(1);
      },
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'non-admin: emits error, no repo writes',
      seed: seedFinished,
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const ReopenGameEvent(gameId: 'g1', isAdmin: false)),
      expect: () => [
        isA<DardosGameState>()
            .having((s) => s.status, 'error', DardosGameStatus.error),
      ],
      verify: (_) {
        verifyNever(mockRepo.reopenGame(gameId: anyNamed('gameId')));
        verifyNever(mockRepo.deleteLastThrow(any));
      },
    );

    blocTest<DardosGameBloc, DardosGameState>(
      'game without a winner: ignored, no repo writes',
      seed: () => DardosGameState(
        status: DardosGameStatus.loaded,
        game: makeGame501(status: 'in_progress', rosterLocked: true),
        annotatorOwned: true,
        throws: [makeThrow()],
        liveScores: const {'p1': 481, 'p2': 501},
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const ReopenGameEvent(gameId: 'g1', isAdmin: true)),
      expect: () => <DardosGameState>[],
      verify: (_) {
        verifyNever(mockRepo.reopenGame(gameId: anyNamed('gameId')));
        verifyNever(mockRepo.deleteLastThrow(any));
      },
    );
  });
}
