import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_game_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_state.dart';

@GenerateNiceMocks([MockSpec<DardosGameRepository>()])
import 'dardos_multi_game_bloc_test.mocks.dart';

// ---------------------------------------------------------------------------
// Fixture
// ---------------------------------------------------------------------------
DardosGameEntity makeGame({
  String id = 'g1',
  String status = 'in_progress',
  String mode = '501',
}) {
  return DardosGameEntity(
    id: id,
    name: 'Game $id',
    mode: mode,
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

void main() {
  late MockDardosGameRepository mockRepo;

  setUp(() {
    mockRepo = MockDardosGameRepository();
  });

  DardosMultiGameBloc buildBloc() => DardosMultiGameBloc(mockRepo);

  // -----------------------------------------------------------------------
  // LoadGamesEvent
  // -----------------------------------------------------------------------
  group('LoadGamesEvent', () {
    blocTest<DardosMultiGameBloc, DardosMultiGameState>(
      'emits loading then success with games list',
      build: () {
        when(mockRepo.getGameHistory()).thenAnswer((_) async =>
            DataSuccess([makeGame(), makeGame(id: 'g2')]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGamesEvent()),
      expect: () => [
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.loading),
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.success)
            .having((s) => s.games.length, 'count', 2),
      ],
    );

    blocTest<DardosMultiGameBloc, DardosMultiGameState>(
      'cancelled games are included in the full list but excluded from ranking queries',
      build: () {
        when(mockRepo.getGameHistory()).thenAnswer((_) async => DataSuccess([
              makeGame(id: 'g1', status: 'finished'),
              makeGame(id: 'g2', status: 'cancelled'),
            ]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGamesEvent()),
      expect: () => [
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.loading),
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.success)
            // Full list contains all 2
            .having((s) => s.games.length, 'total count', 2)
            // Only 1 is non-cancelled
            .having(
              (s) => s.games.where((g) => g.status != 'cancelled').length,
              'non-cancelled',
              1,
            ),
      ],
    );

    blocTest<DardosMultiGameBloc, DardosMultiGameState>(
      'emits error state when repo fails',
      build: () {
        when(mockRepo.getGameHistory()).thenAnswer(
            (_) async => DataFailed(Exception('load error')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGamesEvent()),
      expect: () => [
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.loading),
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.error),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // LoadGamesByModeEvent
  // -----------------------------------------------------------------------
  group('LoadGamesByModeEvent', () {
    blocTest<DardosMultiGameBloc, DardosMultiGameState>(
      'filters games by mode from repo',
      build: () {
        when(mockRepo.queryGamesByMode('cricket')).thenAnswer((_) async =>
            DataSuccess([
              makeGame(id: 'g3', mode: 'cricket'),
            ]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadGamesByModeEvent(mode: 'cricket')),
      expect: () => [
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.loading),
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.success)
            .having((s) => s.games.first.mode, 'mode', 'cricket'),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // RefreshGamesEvent
  // -----------------------------------------------------------------------
  group('RefreshGamesEvent', () {
    blocTest<DardosMultiGameBloc, DardosMultiGameState>(
      're-fetches game history',
      build: () {
        when(mockRepo.getGameHistory()).thenAnswer(
            (_) async => DataSuccess([makeGame()]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(RefreshGamesEvent()),
      expect: () => [
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.loading),
        isA<DardosMultiGameState>()
            .having((s) => s.status, 'status', DardosMultiGameStatus.success),
      ],
      verify: (_) => verify(mockRepo.getGameHistory()).called(1),
    );
  });
}
