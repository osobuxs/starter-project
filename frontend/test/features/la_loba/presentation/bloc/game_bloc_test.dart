import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

// Cubre los flujos básicos del GameBloc actual (repository-driven):
// crear partida, agregar participante, cargar partida y registrar puntaje
// en memoria. Los flujos de cierre de mano / reingreso / eliminación viven
// en game_bloc_new_rules_test.dart.
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

  group('CreateGameEvent', () {
    blocTest<GameBloc, GameState>(
      'emits [loading, gameCreated] when CreateGameEvent succeeds',
      build: () {
        repository.createGameResult = const DataSuccess(_game);
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateGameEvent('Test')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.gameCreated)
            .having((s) => s.game?.id, 'game id', 'g1'),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, error] when CreateGameEvent fails',
      build: () {
        repository.createGameResult =
            DataFailed<GameEntity>(Exception('Empty name'));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateGameEvent('')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.error),
      ],
    );
  });

  group('AddPlayerEvent', () {
    blocTest<GameBloc, GameState>(
      'emits [loading, loaded] when adding a participant succeeds',
      build: () {
        repository.getGameResult = const DataSuccess(_game);
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AddPlayerEvent(gameId: 'g1', participantId: 'p1'),
      ),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loaded)
            .having((s) => s.game?.id, 'game id', 'g1'),
      ],
    );
  });

  group('LoadGameEvent', () {
    blocTest<GameBloc, GameState>(
      'emits [loading, loaded] when the game loads',
      build: () {
        repository.getGameResult = const DataSuccess(_game);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGameEvent('g1')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loaded)
            .having((s) => s.game?.id, 'game id', 'g1'),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, error] when the game fails to load',
      build: () {
        repository.getGameResult =
            DataFailed<GameEntity>(Exception('not found'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGameEvent('g1')),
      expect: () => [
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.error),
      ],
    );
  });

  group('RecordScoreEvent', () {
    blocTest<GameBloc, GameState>(
      'updates in-memory hand scores without persisting',
      build: () => bloc,
      seed: () => const GameState(
        status: GameBlocStatus.loaded,
        game: _game,
      ),
      act: (bloc) => bloc.add(
        const RecordScoreEvent(participantId: 'p1', points: 25),
      ),
      expect: () => [
        isA<GameState>()
            .having((s) => s.currentHandScores, 'scores', {'p1': 25}),
      ],
      verify: (_) {
        expect(repository.createHandCalls, 0);
      },
    );
  });
}

const _game = GameEntity(
  id: 'g1',
  name: 'Test',
  status: 'playing',
  date: 1,
  participantIds: ['p1', 'p2'],
  currentDealerId: 'p1',
  currentHand: 1,
  participantStates: {
    'p1': {'score': 0, 'status': 'active'},
    'p2': {'score': 0, 'status': 'active'},
  },
  winnerId: null,
  hands: <HandEntity>[],
);

class _FakeGameRepository implements GameRepository {
  DataState<GameEntity> createGameResult = const DataSuccess(_game);
  DataState<GameEntity> getGameResult = const DataSuccess(_game);
  int createHandCalls = 0;

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
    return createGameResult;
  }

  @override
  Future<DataState<HandEntity>> createHand(
    String gameId,
    int handNumber,
    String dealerId,
    Map<String, int> scores,
  ) async {
    createHandCalls += 1;
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
    return getGameResult;
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
