import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

// Live scoring: realtime board updates from the repository stream.
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
            .having((s) => s.status, 'status', GameBlocStatus.loading),
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
  final List<String> watchGameCalls = [];
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
  Future<DataState<GameEntity>> getGame(String gameId) async => getGameResult;

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
