import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand_commit.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/game_play_page.dart';

class _MockParticipantBloc
    extends MockBloc<ParticipantEvent, ParticipantState>
    implements ParticipantBloc {}

class _MockMultiGameBloc extends MockBloc<MultiGameEvent, MultiGameState>
    implements MultiGameBloc {}

const _participants = [
  ParticipantEntity(id: 'p1', name: 'Ana'),
  ParticipantEntity(id: 'p2', name: 'Beto'),
  ParticipantEntity(id: 'p3', name: 'Caro'),
];

void main() {
  late _FakeGameRepository repository;
  late GameBloc gameBloc;
  late _MockParticipantBloc participantBloc;
  late _MockMultiGameBloc multiGameBloc;

  setUp(() {
    repository = _FakeGameRepository();
    participantBloc = _MockParticipantBloc();
    multiGameBloc = _MockMultiGameBloc();
    whenListen(
      multiGameBloc,
      const Stream<MultiGameState>.empty(),
      initialState: const MultiGameState(),
    );
  });

  void givenAdmin(bool isAdmin) {
    whenListen(
      participantBloc,
      const Stream<ParticipantState>.empty(),
      initialState: ParticipantState(
        status: ParticipantBlocStatus.loaded,
        participants: _participants,
        isAdmin: isAdmin,
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, GameEntity game) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Created inside the test zone so its async work follows the fake clock.
    repository.game = game;
    gameBloc = GameBloc(repository: repository)..add(LoadGameEvent(game.id));
    addTearDown(gameBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>.value(value: gameBloc),
          BlocProvider<ParticipantBloc>.value(value: participantBloc),
          BlocProvider<MultiGameBloc>.value(value: multiGameBloc),
        ],
        child: MaterialApp(home: GamePlayPage(gameId: game.id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('read-only viewers see the board but cannot enter scores',
      (tester) async {
    givenAdmin(false);
    await pumpPage(tester, _gameAfterOneHand);

    expect(find.text('R1'), findsOneWidget);
    expect(
      find.text('Modo lectura: no tenés permisos para cargar puntajes.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar ronda'), findsNothing);
    expect(find.text('Corregir última mano'), findsNothing);
  });

  testWidgets('shows the rejoin score under the rejoin cell', (tester) async {
    givenAdmin(false);
    await pumpPage(tester, _gameWithRejoin);

    expect(find.byKey(const ValueKey('rejoin-score-1-p1')), findsOneWidget);
    expect(find.text('(40)'), findsOneWidget);
  });

  testWidgets('admin closes a round and the board updates immediately',
      (tester) async {
    givenAdmin(true);
    await pumpPage(tester, _newGame);

    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.tap(find.text('Confirmar ronda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(find.text('R1'), findsOneWidget);
    expect(find.textContaining('Mano 2'), findsOneWidget);
    expect(repository.commits.single.hand.scores, {
      'p1': 12,
      'p2': 3,
      'p3': 0,
    });
  });

  testWidgets('admin decides a rejoin in the retry dialog', (tester) async {
    givenAdmin(true);
    await pumpPage(tester, _gameAfterOneHand);

    await tester.enterText(find.byType(TextField).at(0), '30');
    await tester.tap(find.text('Confirmar ronda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(find.text('Superó 100 puntos'), findsOneWidget);
    expect(find.textContaining('(base: 50)'), findsOneWidget);

    await tester.tap(find.text('Reingresa'));
    await tester.pumpAndSettle();

    expect(find.text('(50)'), findsOneWidget);
    expect(repository.commits.single.hand.rejoinScores, {'p1': 50});
  });
}

const _newGame = GameEntity(
  id: 'g1',
  name: 'Partida',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p1',
  currentHand: 1,
  participantStates: {
    'p1': {'score': 0, 'status': 'active'},
    'p2': {'score': 0, 'status': 'active'},
    'p3': {'score': 0, 'status': 'active'},
  },
);

const _gameAfterOneHand = GameEntity(
  id: 'g1',
  name: 'Partida',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p2',
  currentHand: 2,
  participantStates: {
    'p1': {'score': 80, 'status': 'active'},
    'p2': {'score': 50, 'status': 'active'},
    'p3': {'score': 20, 'status': 'active'},
  },
  hands: [
    HandEntity(
      handNumber: 1,
      dealerId: 'p1',
      scores: {'p1': 80, 'p2': 50, 'p3': 20},
      timestamp: 1,
    ),
  ],
);

const _gameWithRejoin = GameEntity(
  id: 'g1',
  name: 'Partida',
  date: 1,
  participantIds: ['p1', 'p2', 'p3'],
  currentDealerId: 'p2',
  currentHand: 2,
  participantStates: {
    'p1': {'score': 40, 'status': 'active', 'rejoinedAtHand': 1},
    'p2': {'score': 40, 'status': 'active'},
    'p3': {'score': 20, 'status': 'active'},
  },
  hands: [
    HandEntity(
      handNumber: 1,
      dealerId: 'p1',
      scores: {'p1': 105, 'p2': 40, 'p3': 20},
      timestamp: 1,
      rejoinScores: {'p1': 40},
    ),
  ],
);

class _FakeGameRepository implements GameRepository {
  GameEntity? game;
  final List<HandCommit> commits = [];

  @override
  Future<DataState<GameEntity>> getGame(String gameId) async {
    return DataSuccess(game!);
  }

  @override
  Stream<DataState<GameEntity>> watchGame(String gameId) {
    return const Stream.empty();
  }

  @override
  Future<DataState<void>> commitHand(HandCommit commit) async {
    commits.add(commit);
    return const DataSuccess(null);
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
    return DataSuccess(game!);
  }

  @override
  Future<DataState<List<GameEntity>>> getGameHistory() async {
    return const DataSuccess([]);
  }

  @override
  Future<DataState<void>> updateGameStatus(String gameId, String status) async {
    return const DataSuccess(null);
  }
}
