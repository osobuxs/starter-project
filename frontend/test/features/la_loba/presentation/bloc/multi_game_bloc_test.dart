import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';

const _baseGame = GameEntity(
  id: 'g1',
  name: 'Game 1',
  status: 'playing',
  date: 10,
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

void main() {
  late _FakeGameRepository repository;
  late MultiGameBloc bloc;

  setUp(() {
    repository = _FakeGameRepository();
    bloc = MultiGameBloc(repository);
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<MultiGameBloc, MultiGameState>(
    'LoadGamesEvent keeps multiple playing games',
    build: () {
      repository.gamesHistory = [
        _baseGame.copyWith(id: 'g1', date: 100, status: 'playing'),
        _baseGame.copyWith(id: 'g2', date: 90, status: 'playing'),
        _baseGame.copyWith(id: 'g3', date: 80, status: 'paused'),
      ];
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadGamesEvent()),
    expect: () => [
      const MultiGameState(status: MultiGameBlocStatus.loading),
      isA<MultiGameState>()
          .having((s) => s.status, 'status', MultiGameBlocStatus.loaded)
          .having((s) => s.playingGames.length, 'playing count', 2)
          .having((s) => s.pausedGames.length, 'paused count', 1),
    ],
  );

  blocTest<MultiGameBloc, MultiGameState>(
    'PauseGameEvent moves one playing game to paused',
    build: () => bloc,
    seed: () => MultiGameState(
      status: MultiGameBlocStatus.loaded,
      playingGames: [
        _baseGame.copyWith(id: 'g1', status: 'playing'),
        _baseGame.copyWith(id: 'g2', status: 'playing'),
      ],
      pausedGames: const [],
    ),
    act: (bloc) => bloc.add(const PauseGameEvent('g1')),
    expect: () => [
      isA<MultiGameState>()
          .having((s) => s.status, 'status', MultiGameBlocStatus.gamePaused)
          .having((s) => s.playingGames.length, 'playing count', 1)
          .having((s) => s.pausedGames.length, 'paused count', 1)
          .having((s) => s.pausedGames.first.id, 'paused id', 'g1'),
    ],
  );

  blocTest<MultiGameBloc, MultiGameState>(
    'ResumeGameEvent keeps other playing and adds resumed game',
    build: () => bloc,
    seed: () => MultiGameState(
      status: MultiGameBlocStatus.loaded,
      playingGames: [_baseGame.copyWith(id: 'g2', status: 'playing')],
      pausedGames: [_baseGame.copyWith(id: 'g1', status: 'paused')],
    ),
    act: (bloc) => bloc.add(const ResumeGameEvent('g1')),
    expect: () => [
      isA<MultiGameState>()
          .having((s) => s.status, 'status', MultiGameBlocStatus.gameResumed)
          .having((s) => s.playingGames.length, 'playing count', 2)
          .having((s) => s.pausedGames.length, 'paused count', 0),
    ],
  );
}

class _FakeGameRepository implements GameRepository {
  List<GameEntity> gamesHistory = const [];

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
    return DataSuccess(
      GameEntity(
        id: 'created',
        name: name,
        status: 'playing',
        date: 1,
        participantIds: participantIds ?? const [],
        currentDealerId: participantIds != null && participantIds.isNotEmpty
            ? participantIds.first
            : '',
        currentHand: 1,
        participantStates: {
          for (final id in participantIds ?? const <String>[])
            id: {'score': 0, 'status': 'active'},
        },
        hands: const [],
      ),
    );
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
        timestamp: 0,
      ),
    );
  }

  @override
  Future<DataState<GameEntity>> getGame(String gameId) async {
    return DataSuccess(_baseGame.copyWith(id: gameId));
  }

  @override
  Stream<DataState<GameEntity>> watchGame(String gameId) {
    return const Stream.empty();
  }

  @override
  Future<DataState<List<GameEntity>>> getGameHistory() async {
    return DataSuccess(gamesHistory);
  }

  @override
  Future<DataState<void>> updateGameStatus(String gameId, String status) async {
    return const DataSuccess(null);
  }

  @override
  Future<DataState<void>> updateGameWinner(
      String gameId, String winnerId) async {
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
