import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game_over_result.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/partida.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/add_player_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/check_game_over_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/create_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/do_retry_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_history_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/finish_partida_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/record_scores_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/reject_retry_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/start_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

@GenerateNiceMocks([
  MockSpec<CreateGameUseCase>(),
  MockSpec<AddPlayerUseCase>(),
  MockSpec<StartGameUseCase>(),
  MockSpec<RecordScoresUseCase>(),
  MockSpec<FinishPartidaUseCase>(),
  MockSpec<CheckGameOverUseCase>(),
  MockSpec<DoRetryUseCase>(),
  MockSpec<RejectRetryUseCase>(),
  MockSpec<FetchGameUseCase>(),
  MockSpec<FetchGameHistoryUseCase>(),
  MockSpec<GameRepository>(),
])
import 'game_bloc_test.mocks.dart';

void main() {
  late GameBloc bloc;
  late MockCreateGameUseCase mockCreateGame;
  late MockAddPlayerUseCase mockAddPlayer;
  late MockStartGameUseCase mockStartGame;
  late MockRecordScoresUseCase mockRecordScores;
  late MockFinishPartidaUseCase mockFinishPartida;
  late MockCheckGameOverUseCase mockCheckGameOver;
  late MockDoRetryUseCase mockDoRetry;
  late MockRejectRetryUseCase mockRejectRetry;
  late MockFetchGameUseCase mockFetchGame;
  late MockFetchGameHistoryUseCase mockFetchHistory;
  late MockGameRepository mockRepository;

  final now = DateTime.now().millisecondsSinceEpoch;

  setUp(() {
    mockCreateGame = MockCreateGameUseCase();
    mockAddPlayer = MockAddPlayerUseCase();
    mockStartGame = MockStartGameUseCase();
    mockRecordScores = MockRecordScoresUseCase();
    mockFinishPartida = MockFinishPartidaUseCase();
    mockCheckGameOver = MockCheckGameOverUseCase();
    mockDoRetry = MockDoRetryUseCase();
    mockRejectRetry = MockRejectRetryUseCase();
    mockFetchGame = MockFetchGameUseCase();
    mockFetchHistory = MockFetchGameHistoryUseCase();
    mockRepository = MockGameRepository();

    bloc = GameBloc(
      createGame: mockCreateGame,
      addPlayer: mockAddPlayer,
      startGame: mockStartGame,
      recordScores: mockRecordScores,
      finishPartida: mockFinishPartida,
      checkGameOver: mockCheckGameOver,
      doRetry: mockDoRetry,
      rejectRetry: mockRejectRetry,
      fetchGame: mockFetchGame,
      fetchHistory: mockFetchHistory,
      repository: mockRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('CreateGameEvent', () {
    final tGame = GameEntity(
      id: 1,
      name: 'Test',
      status: 'created',
      createdAt: now,
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, gameCreated] when CreateGameEvent succeeds',
      build: () {
        when(mockCreateGame('Test'))
            .thenAnswer((_) async => DataSuccess(tGame));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateGameEvent('Test')),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        GameState(status: GameBlocStatus.gameCreated, game: tGame),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, error] when CreateGameEvent fails',
      build: () {
        when(mockCreateGame(''))
            .thenAnswer((_) async => DataFailed(Exception('Empty name')));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateGameEvent('')),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.error),
      ],
    );
  });

  group('AddPlayerEvent', () {
    final tGame = GameEntity(
      id: 1,
      name: 'Test',
      status: 'created',
      createdAt: now,
      players: const [PlayerEntity(id: 1, name: 'Juan', gameId: 1)],
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, gameCreated] when AddPlayerEvent succeeds',
      build: () {
        when(mockAddPlayer(1, 'Juan')).thenAnswer(
          (_) async => const DataSuccess(
            PlayerEntity(id: 1, name: 'Juan', gameId: 1),
          ),
        );
        when(mockFetchGame(1))
            .thenAnswer((_) async => DataSuccess(tGame));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AddPlayerEvent(gameId: 1, playerName: 'Juan'),
      ),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        GameState(status: GameBlocStatus.gameCreated, game: tGame),
      ],
    );
  });

  group('StartGameEvent', () {
    final tStartedGame = GameEntity(
      id: 1,
      name: 'Test',
      status: 'playing',
      createdAt: now,
      players: const [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1),
      ],
      partidas: [
        PartidaEntity(id: 1, partidaNumber: 1, gameId: 1, createdAt: now),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, playing] when StartGameEvent succeeds',
      build: () {
        when(mockStartGame(1))
            .thenAnswer((_) async => DataSuccess(tStartedGame));
        return bloc;
      },
      act: (bloc) => bloc.add(const StartGameEvent(1)),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        GameState(
          status: GameBlocStatus.playing,
          game: tStartedGame,
          currentPartidaNumber: 1,
          currentPartidaId: 1,
        ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [loading, error] when StartGameEvent fails (< 2 players)',
      build: () {
        when(mockStartGame(1)).thenAnswer(
          (_) async => DataFailed(Exception('Need 2 players')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const StartGameEvent(1)),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.error),
      ],
    );
  });

  group('RecordScoreEvent', () {
    blocTest<GameBloc, GameState>(
      'updates in-memory scores without DB call',
      build: () => bloc,
      seed: () => const GameState(
        status: GameBlocStatus.playing,
        currentPartidaScores: {},
      ),
      act: (bloc) => bloc.add(
        const RecordScoreEvent(playerId: 1, points: 25),
      ),
      expect: () => [
        isA<GameState>()
            .having((s) => s.currentPartidaScores, 'scores', {1: 25}),
      ],
      verify: (_) {
        verifyZeroInteractions(mockRecordScores);
      },
    );
  });

  group('LoadHistoryEvent', () {
    blocTest<GameBloc, GameState>(
      'emits [loading, historyLoaded] when LoadHistoryEvent succeeds',
      build: () {
        final tGames = [
          GameEntity(id: 1, name: 'Game 1', createdAt: now),
          GameEntity(id: 2, name: 'Game 2', createdAt: now - 1000),
        ];
        when(mockFetchHistory())
            .thenAnswer((_) async => DataSuccess(tGames));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHistoryEvent()),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.historyLoaded)
            .having((s) => s.games.length, 'games count', 2),
      ],
    );
  });

  group('LoadGameEvent', () {
    blocTest<GameBloc, GameState>(
      'emits playing state for active game',
      build: () {
        final tGame = GameEntity(
          id: 1,
          name: 'Test',
          status: 'playing',
          createdAt: now,
          partidas: [
            PartidaEntity(
              id: 3,
              partidaNumber: 3,
              gameId: 1,
              createdAt: now,
            ),
          ],
        );
        when(mockFetchGame(1))
            .thenAnswer((_) async => DataSuccess(tGame));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGameEvent(1)),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.playing)
            .having((s) => s.currentPartidaNumber, 'partida', 3)
            .having((s) => s.currentPartidaId, 'partidaId', 3),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits gameOver state for finished game',
      build: () {
        final tGame = GameEntity(
          id: 1,
          name: 'Test',
          status: 'finished',
          createdAt: now,
        );
        when(mockFetchGame(1))
            .thenAnswer((_) async => DataSuccess(tGame));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGameEvent(1)),
      expect: () => [
        const GameState(status: GameBlocStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameBlocStatus.gameOver),
      ],
    );
  });
}
