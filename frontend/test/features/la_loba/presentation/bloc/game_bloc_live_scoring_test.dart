import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand_commit.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

// Live scoring: realtime board updates from the repository stream and
// instant (non-blocking) hand commits.
void main() {
  late _FakeGameRepository repository;

  setUp(() {
    repository = _FakeGameRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  group('Realtime board (watchGame)', () {
    blocTest<GameBloc, GameState>(
      'applies remote game updates after LoadGameEvent',
      build: () => GameBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const LoadGameEvent('g1'));
        await pumpEventQueue();
        repository.pushRemote(_remoteAfterHand1);
      },
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loaded)
            .having((s) => s.game, 'game', _game),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loaded)
            .having((s) => s.game, 'game', _remoteAfterHand1),
      ],
      verify: (_) {
        expect(repository.watchGameCalls, ['g1']);
      },
    );

    blocTest<GameBloc, GameState>(
      'keeps the scores the user is typing when a remote update arrives',
      build: () => GameBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const LoadGameEvent('g1'));
        await pumpEventQueue();
        bloc.add(const RecordScoreEvent(participantId: 'p1', points: 7));
        await pumpEventQueue();
        repository.pushRemote(_remoteAfterHand1);
      },
      skip: 2,
      expect: () => [
        isA<GameState>()
            .having((s) => s.currentHandScores, 'scores', {'p1': 7}),
        isA<GameState>()
            .having((s) => s.game, 'game', _remoteAfterHand1)
            .having((s) => s.currentHandScores, 'scores', {'p1': 7}),
      ],
    );

    blocTest<GameBloc, GameState>(
      'signals gameFinished when a remote update finishes the game',
      build: () => GameBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const LoadGameEvent('g1'));
        await pumpEventQueue();
        repository.pushRemote(
          _remoteAfterHand1.copyWith(status: 'finished', winnerId: 'p2'),
        );
      },
      skip: 2,
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.gameFinished)
            .having((s) => s.game?.winnerId, 'winner', 'p2'),
      ],
    );

    blocTest<GameBloc, GameState>(
      'ignores stream errors without touching the board',
      build: () => GameBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const LoadGameEvent('g1'));
        await pumpEventQueue();
        repository.pushRemoteFailure(Exception('offline'));
      },
      skip: 2,
      expect: () => <GameState>[],
    );

    blocTest<GameBloc, GameState>(
      'buffers remote updates while the retry dialog is open',
      build: () => GameBloc(repository: repository),
      act: (bloc) async {
        repository.getGameResult = const DataSuccess(_retryGame);
        bloc.add(const LoadGameEvent('g1'));
        await pumpEventQueue();
        bloc.add(const RecordScoreEvent(participantId: 'p1', points: 5));
        bloc.add(const FinishPartidaEvent('g1'));
        await pumpEventQueue();
        repository.pushRemote(_remoteAfterHand1);
      },
      skip: 3,
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.retryRequired)
            .having((s) => s.game?.id, 'game id', 'g1')
            .having((s) => s.game?.currentHand, 'hand', 1),
      ],
    );

    test('cancels the subscription on close', () async {
      final bloc = GameBloc(repository: repository);
      bloc.add(const LoadGameEvent('g1'));
      await pumpEventQueue();
      expect(repository.hasRemoteListener, isTrue);

      await bloc.close();

      expect(repository.hasRemoteListener, isFalse);
    });
  });

  group('Instant score entry (commitHand)', () {
    blocTest<GameBloc, GameState>(
      'emits handFinished with the locally computed game before the write '
      'completes',
      build: () {
        repository.commitCompleter = Completer<DataState<void>>();
        return GameBloc(repository: repository);
      },
      seed: () => const GameState(
        status: GameBlocStatus.loaded,
        game: _game,
        currentHandScores: {'p1': 10, 'p2': 3},
      ),
      act: (bloc) => bloc.add(const FinishPartidaEvent('g1')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.handFinished)
            .having((s) => s.currentHandScores, 'scores', isEmpty)
            .having((s) => s.game?.currentHand, 'hand', 2)
            .having((s) => s.game?.currentDealerId, 'dealer', 'p2')
            .having(
              (s) => s.game?.participantStates,
              'states',
              _remoteAfterHand1.participantStates,
            )
            .having((s) => s.game?.hands.single.scores, 'hand scores',
                {'p1': 10, 'p2': 3, 'p3': 0})
            .having((s) => s.game?.hands.single.dealerId, 'hand dealer', 'p1'),
      ],
      verify: (_) {
        expect(repository.getGameCalls, 0);
        expect(repository.commits, hasLength(1));
        final commit = repository.commits.single;
        expect(commit.gameId, 'g1');
        expect(commit.hand.handNumber, 1);
        expect(commit.hand.dealerId, 'p1');
        expect(commit.hand.scores, {'p1': 10, 'p2': 3, 'p3': 0});
        expect(commit.nextHandNumber, 2);
        expect(commit.nextDealerId, 'p2');
        expect(commit.participantStates, _remoteAfterHand1.participantStates);
        expect(commit.winnerId, isNull);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits gameFinished locally and commits winner when one survivor remains',
      build: () => GameBloc(repository: repository),
      seed: () => const GameState(
        status: GameBlocStatus.loaded,
        game: _twoPlayersGame,
        currentHandScores: {'p1': 5, 'p2': 0},
      ),
      act: (bloc) => bloc.add(const FinishPartidaEvent('g1')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.gameFinished)
            .having((s) => s.game?.status, 'game status', 'finished')
            .having((s) => s.game?.winnerId, 'winner', 'p2')
            .having((s) => s.game?.hands.length, 'hands', 1),
      ],
      verify: (_) {
        expect(repository.commits.single.winnerId, 'p2');
        expect(repository.commits.single.participantIds, ['p1', 'p2']);
        expect(repository.getGameCalls, 0);
      },
    );

    blocTest<GameBloc, GameState>(
      'keeps the local board and reports an error when the write fails',
      build: () {
        repository.commitResult = DataFailed<void>(Exception('denied'));
        return GameBloc(repository: repository);
      },
      seed: () => const GameState(
        status: GameBlocStatus.loaded,
        game: _game,
        currentHandScores: {'p1': 10, 'p2': 3},
      ),
      act: (bloc) => bloc.add(const FinishPartidaEvent('g1')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.handFinished),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.error)
            .having((s) => s.error, 'error', contains('No se pudo guardar'))
            .having((s) => s.game?.currentHand, 'hand', 2)
            .having((s) => s.game?.hands.length, 'hands', 1),
      ],
    );

    blocTest<GameBloc, GameState>(
      'commits only after the retry dialog is resolved',
      build: () => GameBloc(repository: repository),
      seed: () => const GameState(
        status: GameBlocStatus.loaded,
        game: _retryGame,
        currentHandScores: {'p1': 5},
      ),
      act: (bloc) async {
        bloc.add(const FinishPartidaEvent('g1'));
        await pumpEventQueue();
        expect(repository.commits, isEmpty);
        bloc.add(
          const ResolveRetryDecisionEvent(participantId: 'p1', rejoin: true),
        );
      },
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.retryRequired),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.handFinished)
            .having((s) => s.game?.participantStates['p1']?['score'],
                'p1 score', 50)
            .having((s) => s.game?.hands.single.scores['p1'], 'p1 hand', 5),
      ],
      verify: (_) {
        expect(repository.commits, hasLength(1));
        expect(
          repository.commits.single.participantStates['p1']?['rejoinedAtHand'],
          1,
        );
      },
    );
  });
}

const _game = GameEntity(
  id: 'g1',
  name: 'Live',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p1',
  currentHand: 1,
  participantStates: {
    'p1': {'score': 0, 'status': 'active'},
    'p2': {'score': 0, 'status': 'active'},
    'p3': {'score': 0, 'status': 'active'},
  },
  hands: <HandEntity>[],
);

const _remoteAfterHand1 = GameEntity(
  id: 'g1',
  name: 'Live',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p2',
  currentHand: 2,
  participantStates: {
    'p1': {'score': 10, 'status': 'active'},
    'p2': {'score': 3, 'status': 'active'},
    'p3': {'score': 0, 'status': 'active'},
  },
  hands: <HandEntity>[
    HandEntity(
      handNumber: 1,
      dealerId: 'p1',
      scores: {'p1': 10, 'p2': 3, 'p3': 0},
      timestamp: 1,
    ),
  ],
);

// p1 goes over the limit and p2 is the only survivor.
const _twoPlayersGame = GameEntity(
  id: 'g1',
  name: 'Live',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2'],
  currentDealerId: 'p1',
  currentHand: 1,
  participantStates: {
    'p1': {'score': 98, 'status': 'active'},
    'p2': {'score': 40, 'status': 'active'},
  },
  hands: <HandEntity>[],
);

// p1 goes over the limit with 5 points while two others survive.
const _retryGame = GameEntity(
  id: 'g1',
  name: 'Live',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p1',
  currentHand: 1,
  participantStates: {
    'p1': {'score': 98, 'status': 'active'},
    'p2': {'score': 50, 'status': 'active'},
    'p3': {'score': 40, 'status': 'active'},
  },
  hands: <HandEntity>[],
);

class _FakeGameRepository implements GameRepository {
  DataState<GameEntity> getGameResult = const DataSuccess(_game);
  int getGameCalls = 0;
  final List<String> watchGameCalls = [];
  final List<HandCommit> commits = [];
  DataState<void> commitResult = const DataSuccess(null);
  Completer<DataState<void>>? commitCompleter;
  final StreamController<DataState<GameEntity>> _remote =
      StreamController<DataState<GameEntity>>.broadcast();

  bool get hasRemoteListener => _remote.hasListener;

  void pushRemote(GameEntity game) => _remote.add(DataSuccess(game));

  void pushRemoteFailure(Exception error) =>
      _remote.add(DataFailed<GameEntity>(error));

  Future<void> dispose() => _remote.close();

  @override
  Stream<DataState<GameEntity>> watchGame(String gameId) {
    watchGameCalls.add(gameId);
    return _remote.stream;
  }

  @override
  Future<DataState<GameEntity>> getGame(String gameId) async {
    getGameCalls += 1;
    return getGameResult;
  }

  @override
  Future<DataState<void>> commitHand(HandCommit commit) {
    commits.add(commit);
    return commitCompleter?.future ?? Future.value(commitResult);
  }

  @override
  Future<DataState<void>> addParticipantToGame(
    String gameId,
    String participantId, {
    int? insertIndex,
  }) async {
    return const DataSuccess(null);
  }

  @override
  Future<DataState<GameEntity>> createGame(
    String name, [
    List<String>? participantIds,
  ]) async {
    return const DataSuccess(_game);
  }

  @override
  Future<DataState<HandEntity>> createHand(
    String gameId,
    int handNumber,
    String dealerId,
    Map<String, int> scores,
  ) async {
    return DataSuccess(
      HandEntity(
        handNumber: handNumber,
        dealerId: dealerId,
        scores: scores,
        timestamp: 1,
      ),
    );
  }

  @override
  Future<DataState<List<GameEntity>>> getGameHistory() async {
    return const DataSuccess([]);
  }

  @override
  Future<DataState<void>> updateGameStatus(String gameId, String status) async {
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateGameWinner(
    String gameId,
    String winnerId,
  ) async {
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  ) async {
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateParticipantStatsOnGameFinished(
    List<String> participantIds,
    String winnerId,
  ) async {
    return const DataSuccess(null);
  }
}
