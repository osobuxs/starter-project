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

void main() {
  late _FakeGameRepository repository;
  late GameBloc bloc;

  setUp(() {
    repository = _FakeGameRepository();
    bloc = GameBloc(repository: repository);
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<GameBloc, GameState>(
    'FinishPartidaEvent emits retryRequired when participant exceeds 100',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _initialGame,
      currentHandScores: const {'p1': 3, 'p2': 0, 'p3': 0},
    ),
    act: (bloc) => bloc.add(const FinishPartidaEvent('g1')),
    expect: () => [
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.retryRequired)
          .having((s) => s.currentRetryParticipantId, 'retryId', 'p1')
          .having((s) => s.pendingRetryParticipantIds.length, 'pending', 1),
    ],
  );

  blocTest<GameBloc, GameState>(
    'FinishPartidaEvent fails and does not persist hand when all active players exceed 100',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _allWillExceedGame,
      currentHandScores: const {'p1': 2, 'p2': 1},
    ),
    act: (bloc) => bloc.add(const FinishPartidaEvent('g2')),
    expect: () => [
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.error)
          .having(
            (s) => s.error,
            'error',
            'No se puede cerrar la mano: todos los participantes activos superan 100 puntos.',
          ),
    ],
    verify: (_) {
      expect(repository.commitHandCalls, 0);
    },
  );

  blocTest<GameBloc, GameState>(
    'FinishPartidaEvent auto-finishes with unique survivor without retry dialog',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _uniqueSurvivorGame,
      currentHandScores: const {'p1': 11, 'p2': 7, 'p3': 0},
    ),
    act: (bloc) => bloc.add(const FinishPartidaEvent('g3')),
    expect: () => [
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.gameFinished),
    ],
    verify: (_) {
      expect(repository.commitHandCalls, 1);
      expect(repository.lastCommit?.hand.handNumber, 4);
      expect(repository.lastCommit?.hand.scores, {'p1': 11, 'p2': 7, 'p3': 0});

      final persistedStates = repository.lastUpdatedParticipantStates;
      expect(
        persistedStates?['p1'],
        {'score': 101, 'status': 'eliminated', 'eliminatedAtHand': 4},
      );
      expect(
        persistedStates?['p2'],
        {'score': 102, 'status': 'eliminated', 'eliminatedAtHand': 4},
      );
      expect(
        persistedStates?['p3'],
        {'score': 40, 'status': 'active'},
      );
      expect(repository.lastWinnerId, 'p3');
    },
  );

  blocTest<GameBloc, GameState>(
    'Rejecting retry after finish event keeps game in progress when multiple survivors remain',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _initialGame,
      currentHandScores: const {'p1': 3, 'p2': 0, 'p3': 0},
    ),
    act: (bloc) {
      bloc.add(const FinishPartidaEvent('g1'));
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p1', rejoin: false),
      );
    },
    expect: () => [
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.retryRequired),
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.handFinished),
    ],
  );

  blocTest<GameBloc, GameState>(
    'Rejecting retry keeps rejoinedAtHand history while marking elimination hand',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _gameWithPreviousRejoin,
      currentHandScores: const {'p1': 2, 'p2': 0},
    ),
    act: (bloc) {
      bloc.add(const FinishPartidaEvent('g4'));
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p1', rejoin: false),
      );
    },
    verify: (_) {
      final persistedStates = repository.lastUpdatedParticipantStates;
      expect(persistedStates?['p1']?['rejoinedAtHand'], 2);
      expect(persistedStates?['p1']?['eliminatedAtHand'], 7);
      expect(persistedStates?['p1']?['status'], 'eliminated');
    },
  );

  blocTest<GameBloc, GameState>(
    'Two over-limit participants that both rejoin receive the same fixed base score',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _doubleOverLimitSameBatchGame,
      currentHandScores: const {'p1': 3, 'p2': 2, 'p3': 0, 'p4': 0},
    ),
    act: (bloc) {
      bloc.add(const FinishPartidaEvent('g5'));
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p1', rejoin: true),
      );
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p2', rejoin: true),
      );
    },
    expect: () => [
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.retryRequired)
          .having((s) => s.pendingRetryParticipantIds, 'pending', [
        'p1',
        'p2'
      ]).having((s) => s.currentRetryParticipantId, 'currentRetry', 'p1'),
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.retryRequired)
          .having((s) => s.pendingRetryParticipantIds, 'pending', [
        'p2'
      ]).having((s) => s.currentRetryParticipantId, 'currentRetry', 'p2'),
      isA<GameState>()
          .having((s) => s.status, 'status', GameBlocStatus.handFinished),
    ],
    verify: (_) {
      final persistedStates = repository.lastUpdatedParticipantStates;
      expect(persistedStates?['p1']?['score'], 90);
      expect(persistedStates?['p2']?['score'], 90);
      expect(persistedStates?['p1']?['status'], 'active');
      expect(persistedStates?['p2']?['status'], 'active');
      expect(persistedStates?['p1']?['rejoinedAtHand'], 6);
      expect(persistedStates?['p2']?['rejoinedAtHand'], 6);
    },
  );

  blocTest<GameBloc, GameState>(
    'In mixed retry decisions, rejoin still uses fixed batch base score',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _doubleOverLimitSameBatchGame,
      currentHandScores: const {'p1': 3, 'p2': 2, 'p3': 0, 'p4': 0},
    ),
    act: (bloc) {
      bloc.add(const FinishPartidaEvent('g5'));
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p1', rejoin: true),
      );
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p2', rejoin: false),
      );
    },
    verify: (_) {
      final persistedStates = repository.lastUpdatedParticipantStates;
      expect(persistedStates?['p1']?['score'], 90);
      expect(persistedStates?['p1']?['status'], 'active');
      expect(persistedStates?['p2']?['status'], 'eliminated');
      expect(persistedStates?['p2']?['score'], 102);
      expect(persistedStates?['p2']?['eliminatedAtHand'], 6);
    },
  );

  blocTest<GameBloc, GameState>(
    'When the mano is eliminated, the previous dealer deals again',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _manoAboutToBeEliminatedGame,
      currentHandScores: const {'p1': 0, 'p2': 5, 'p3': 0, 'p4': 0},
    ),
    act: (bloc) {
      bloc.add(const FinishPartidaEvent('g6'));
      bloc.add(
        const ResolveRetryDecisionEvent(participantId: 'p2', rejoin: false),
      );
    },
    verify: (_) {
      expect(repository.lastDealerId, 'p1');
    },
  );

  blocTest<GameBloc, GameState>(
    'Dealer keeps rotating in the round after the mano was eliminated',
    build: () => bloc,
    seed: () => GameState(
      status: GameBlocStatus.loaded,
      game: _afterManoEliminatedGame,
      currentHandScores: const {'p1': 0, 'p3': 0, 'p4': 0},
    ),
    act: (bloc) => bloc.add(const FinishPartidaEvent('g7')),
    verify: (_) {
      expect(repository.lastDealerId, 'p3');
    },
  );
}

const _manoAboutToBeEliminatedGame = GameEntity(
  id: 'g6',
  name: 'Mano eliminado',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3', 'p4'],
  currentDealerId: 'p1',
  currentHand: 3,
  participantStates: {
    'p1': {'score': 10, 'status': 'active'},
    'p2': {'score': 99, 'status': 'active'},
    'p3': {'score': 20, 'status': 'active'},
    'p4': {'score': 30, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

// p1 dealt again because p2 (the mano) was eliminated, so p3 was mano.
const _afterManoEliminatedGame = GameEntity(
  id: 'g7',
  name: 'Ronda siguiente',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3', 'p4'],
  currentDealerId: 'p1',
  currentHand: 4,
  participantStates: {
    'p1': {'score': 10, 'status': 'active'},
    'p2': {'score': 104, 'status': 'eliminated', 'eliminatedAtHand': 3},
    'p3': {'score': 20, 'status': 'active'},
    'p4': {'score': 30, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

const _initialGame = GameEntity(
  id: 'g1',
  name: 'Partida',
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
  winnerId: null,
  hands: <HandEntity>[],
);

const _allWillExceedGame = GameEntity(
  id: 'g2',
  name: 'Todos superan',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2'],
  currentDealerId: 'p1',
  currentHand: 3,
  participantStates: {
    'p1': {'score': 99, 'status': 'active'},
    'p2': {'score': 100, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

const _uniqueSurvivorGame = GameEntity(
  id: 'g3',
  name: 'Superviviente único',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p1',
  currentHand: 4,
  participantStates: {
    'p1': {'score': 90, 'status': 'active'},
    'p2': {'score': 95, 'status': 'active'},
    'p3': {'score': 40, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

const _gameWithPreviousRejoin = GameEntity(
  id: 'g4',
  name: 'Historial reingreso',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2'],
  currentDealerId: 'p1',
  currentHand: 7,
  participantStates: {
    'p1': {'score': 99, 'status': 'active', 'rejoinedAtHand': 2},
    'p2': {'score': 60, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

const _doubleOverLimitSameBatchGame = GameEntity(
  id: 'g5',
  name: 'Doble reingreso lote',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2', 'p3', 'p4'],
  currentDealerId: 'p1',
  currentHand: 6,
  participantStates: {
    'p1': {'score': 100, 'status': 'active'},
    'p2': {'score': 100, 'status': 'active'},
    'p3': {'score': 90, 'status': 'active'},
    'p4': {'score': 70, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

class _FakeGameRepository implements GameRepository {
  GameEntity _gameAfterReload = _initialGame;
  int commitHandCalls = 0;
  HandCommit? lastCommit;
  String? lastWinnerId;
  String? lastDealerId;
  Map<String, dynamic>? lastUpdatedParticipantStates;

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
    return DataSuccess(_initialGame.copyWith(name: name));
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
  Future<DataState<GameEntity>> getGame(String gameId) async {
    return DataSuccess(_gameAfterReload);
  }

  @override
  Stream<DataState<GameEntity>> watchGame(String gameId) {
    return const Stream.empty();
  }

  @override
  Future<DataState<List<GameEntity>>> getGameHistory() async {
    return const DataSuccess([]);
  }

  @override
  Future<DataState<void>> commitHand(HandCommit commit) async {
    commitHandCalls += 1;
    lastCommit = commit;
    lastUpdatedParticipantStates = commit.participantStates;
    lastDealerId = commit.nextDealerId;
    lastWinnerId = commit.winnerId;
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateGameStatus(String gameId, String status) async {
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateGameWinner(
      String gameId, String winnerId) async {
    _gameAfterReload = _gameAfterReload.copyWith(
      status: 'finished',
      winnerId: winnerId,
    );
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateParticipantScores(
    String gameId,
    String currentDealerId,
    int currentHand,
    Map<String, dynamic> participantStates,
  ) async {
    _gameAfterReload = _gameAfterReload.copyWith(
      currentDealerId: currentDealerId,
      currentHand: currentHand,
      participantStates: participantStates,
      status: _gameAfterReload.status,
    );
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
