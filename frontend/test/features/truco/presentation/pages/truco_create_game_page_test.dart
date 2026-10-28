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
    final cubit = TrucoCreateGameCubit(
      gameRepository,
      now: () => DateTime(2026, 10, 28),
    );
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
    expect(find.text('Ana'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('truco-seat-p1')),
        matching: find.text('Reparte'),
      ),
      findsOneWidget,
      reason: 'A1 deals first by default',
    );

    // Beto deals first: the table moves the marker to his seat.
    await tester.tap(find.byKey(const ValueKey('truco-first-dealer-p2')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('truco-seat-p2')),
        matching: find.text('Reparte'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Comenzar partida'));
    await tester.pumpAndSettle();

    expect(gameRepository.game!.mode, TrucoMode.oneVsOne);
    expect(gameRepository.game!.teamA.playerIds, ['p1']);
    expect(gameRepository.game!.teamB.playerIds, ['p2']);
    expect(gameRepository.game!.name, 'Truco 28/10');
    expect(gameRepository.game!.seatingOrder, ['p1', 'p2']);
    expect(gameRepository.game!.currentDealerId, 'p2');
    expect(openedGameId, 'created');
  });

  testWidgets('fields follow the order and the name is required',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = TrucoCreateGameCubit(
      FakeTrucoGameRepository(),
      now: () => DateTime(2026, 10, 28),
    );
    final participantBloc = TrucoParticipantBloc(
      FakeTrucoParticipantRepository(const [
        TrucoParticipant(id: 'p1', name: 'Ana'),
        TrucoParticipant(id: 'p2', name: 'Beto'),
      ]),
      FakeAuth(email: 'lfexevega95@gmail.com'),
    )..add(const FetchTrucoParticipantsEvent());
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

    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    expect(top('Modo'), lessThan(top('Nombre de la partida')));
    expect(top('Nombre de la partida'), lessThan(top('Equipos')));
    expect(top('Equipos'), lessThan(top('Jugadores')));
    expect(top('Jugadores'), lessThan(top('Quién reparte primero')));
    expect(top('Quién reparte primero'), lessThan(top('Ubicación en la mesa')));

    final nameField = find.byKey(const ValueKey('truco-game-name'));
    expect(
      tester.widget<TextFormField>(nameField).initialValue,
      'Truco 28/10',
    );

    await tester.tap(find.text('1 vs 1'));
    await tester.tap(find.byKey(const ValueKey('pick-p1-a')));
    await tester.tap(find.byKey(const ValueKey('pick-p2-b')));
    await tester.enterText(nameField, '   ');
    await tester.pumpAndSettle();

    expect(find.text('La partida necesita un nombre.'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Comenzar partida'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
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
