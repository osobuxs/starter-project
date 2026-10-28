import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_cubit.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_create_game_page.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/truco_route_names.dart';

import '../../support/truco_fakes.dart';

void main() {
  testWidgets('admin seats two players, sees the table and starts the game',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final gameRepository = FakeTrucoGameRepository();
    final cubit = TrucoCreateGameCubit(gameRepository);
    final participantBloc = TrucoParticipantBloc(
      FakeTrucoParticipantRepository(const [
        TrucoParticipant(id: 'p1', name: 'Ana'),
        TrucoParticipant(id: 'p2', name: 'Beto'),
      ]),
      FakeAuth(email: 'lfexevega95@gmail.com'),
    )..add(const FetchTrucoParticipantsEvent());
    addTearDown(cubit.close);
    addTearDown(participantBloc.close);
    String? openedGameId;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: participantBloc),
        ],
        child: MaterialApp(
          home: const TrucoCreateGamePage(),
          onGenerateRoute: (settings) {
            if (settings.name == TrucoRouteNames.play) {
              openedGameId = settings.arguments as String?;
            }
            return MaterialPageRoute(builder: (_) => const Text('Tablero'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 vs 1'));
    await tester.pumpAndSettle();
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('B1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pick-p1-a')));
    await tester.tap(find.byKey(const ValueKey('pick-p2-b')));
    await tester.pumpAndSettle();

    // Seats now show the chosen players instead of the placeholders.
    expect(find.text('A1'), findsOneWidget); // avatar inside team card
    expect(find.text('Ana'), findsNWidgets(3));

    await tester.tap(find.text('Comenzar partida'));
    await tester.pumpAndSettle();

    expect(gameRepository.game!.mode, TrucoMode.oneVsOne);
    expect(gameRepository.game!.teamA.playerIds, ['p1']);
    expect(gameRepository.game!.teamB.playerIds, ['p2']);
    expect(openedGameId, 'created');
  });

  testWidgets('start stays disabled until the table is complete',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = TrucoCreateGameCubit(FakeTrucoGameRepository());
    final participantBloc = TrucoParticipantBloc(
      FakeTrucoParticipantRepository(),
      FakeAuth(),
    );
    addTearDown(cubit.close);
    addTearDown(participantBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: participantBloc),
        ],
        child: const MaterialApp(home: TrucoCreateGamePage()),
      ),
    );

    await tester.pumpAndSettle();
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Comenzar partida'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Cada equipo debe tener 2 jugadores.'), findsOneWidget);
  });
}
