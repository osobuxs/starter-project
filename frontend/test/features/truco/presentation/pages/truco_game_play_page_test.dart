import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_game_play_page.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_matchstick_painter.dart';

import '../../support/truco_fakes.dart';

const _players = [
  TrucoParticipant(id: 'a1', name: 'Ana'),
  TrucoParticipant(id: 'a2', name: 'Alma'),
  TrucoParticipant(id: 'b1', name: 'Beto'),
  TrucoParticipant(id: 'b2', name: 'Bruno'),
];

const _game = TrucoGame(
  id: 'g1',
  name: 'Final del jueves',
  currentDealerId: 'b1',
  mode: TrucoMode.twoVsTwo,
  targetScore: 30,
  teamA: TrucoTeam(name: 'Nosotros', playerIds: ['a1', 'a2']),
  teamB: TrucoTeam(name: 'Ellos', playerIds: ['b1', 'b2']),
  date: 1,
  scoreA: 17,
  scoreB: 4,
  currentHand: 2,
  hands: [
    TrucoHand(
      handNumber: 1,
      pointsA: 17,
      pointsB: 4,
      timestamp: 1000,
      scoreABefore: 0,
      scoreBBefore: 0,
    ),
  ],
);

void main() {
  late FakeTrucoGameRepository repository;

  Future<void> pump(
    WidgetTester tester, {
    required bool admin,
    Size size = const Size(1000, 2800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeTrucoGameRepository()..game = _game;
    final gameBloc = TrucoGameBloc(
      repository: repository,
      now: () => DateTime.fromMillisecondsSinceEpoch(2000),
    )..add(const LoadTrucoGameEvent('g1'));
    final participantBloc = TrucoParticipantBloc(
      FakeTrucoParticipantRepository(_players),
      FakeAuth(email: admin ? 'lfexevega95@gmail.com' : 'viewer@example.com'),
    )
      ..add(const CheckTrucoAdminStatusEvent())
      ..add(const FetchTrucoParticipantsEvent());
    addTearDown(gameBloc.close);
    addTearDown(participantBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: gameBloc),
          BlocProvider.value(value: participantBloc),
        ],
        child: MaterialApp(
          home: TrucoGamePlayPage(
            gameId: 'g1',
            now: () => DateTime.fromMillisecondsSinceEpoch(2000),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('board shows team names, members, totals and matchsticks',
      (tester) async {
    await pump(tester, admin: false);

    expect(find.byKey(const ValueKey('truco-team-name-a')), findsOneWidget);
    expect(find.text('Nosotros'), findsWidgets);
    expect(find.text('Ana · Alma'), findsOneWidget);
    expect(find.text('Beto · Bruno'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('truco-total-a'))).data,
      '17',
    );
    expect(find.text('MALAS'), findsNWidgets(2));
    expect(find.text('BUENAS'), findsNWidgets(2));
    expect(find.text('en las buenas'), findsOneWidget);

    expect(sticks('a', 'malas').groups, [5, 5, 5]);
    expect(sticks('a', 'buenas').groups, [2]);
    expect(sticks('b', 'malas').groups, [4]);
    expect(sticks('b', 'buenas').groups, isEmpty);
  });

  testWidgets('viewers get a read-only board without the correction pencil',
      (tester) async {
    await pump(tester, admin: false);

    expect(
      find.text('Modo lectura: solo el administrador puede cargar puntos.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar'), findsNothing);
    expect(find.byTooltip('Corregir última mano'), findsNothing);
  });

  testWidgets('shows the game name and the table with dealer and mano',
      (tester) async {
    await pump(tester, admin: false);

    expect(find.text('Final del jueves'), findsOneWidget);
    expect(find.textContaining('a 30 puntos'), findsWidgets);
    expect(find.byKey(const ValueKey('truco-table')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('truco-seat-b1')),
        matching: find.text('Reparte'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('truco-seat-a2')),
        matching: find.text('Mano'),
      ),
      findsOneWidget,
    );
    expect(find.text('Reparte'), findsOneWidget);
  });

  testWidgets('fits a phone width without overflow', (tester) async {
    await pump(tester, admin: true, size: const Size(360, 2400));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('truco-table')), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('entry shows 0 with minus disabled and no keyboard input',
      (tester) async {
    await pump(tester, admin: true);

    expect(find.byType(TextField), findsNothing);
    expect(entry(tester, 'a'), '0');
    expect(entry(tester, 'b'), '0');
    expect(button(tester, 'minus', 'a').onPressed, isNull);
    expect(button(tester, 'plus', 'a').onPressed, isNotNull);
  });

  testWidgets('plus stops at the points the team still needs', (tester) async {
    await pump(tester, admin: true);

    // Team A has 17 of 30: it needs 13.
    for (var i = 0; i < 13; i++) {
      await tester.tap(find.byKey(const ValueKey('truco-plus-a')));
      await tester.pump();
    }

    expect(entry(tester, 'a'), '13');
    expect(button(tester, 'plus', 'a').onPressed, isNull);
    expect(button(tester, 'minus', 'a').onPressed, isNotNull);
  });

  testWidgets('admin confirms a hand and the board updates at once',
      (tester) async {
    await pump(tester, admin: true);

    await tester.tap(find.byKey(const ValueKey('truco-plus-a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('truco-plus-a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('truco-plus-b')));
    await tester.pump();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('truco-total-a'))).data,
      '19',
    );
    expect(sticks('a', 'buenas').groups, [4]);
    expect(sticks('b', 'malas').groups, [5]);
    expect(find.textContaining('Mano 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('truco-hand-2')), findsOneWidget);
    expect(repository.commits.single.hand.pointsA, 2);
    expect(repository.commits.single.hand.pointsB, 1);
    expect(repository.commits.single.hand.dealerId, 'b1');
    // The deck moves one seat and the entries reset for the next hand.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('truco-seat-a2')),
        matching: find.text('Reparte'),
      ),
      findsOneWidget,
    );
    expect(entry(tester, 'a'), '0');
  });

  testWidgets('admin corrects the last hand with the pencil', (tester) async {
    await pump(tester, admin: true);

    await tester.tap(find.byTooltip('Corregir última mano'));
    await tester.pumpAndSettle();

    expect(find.text('Editando mano 1'), findsOneWidget);
    expect(entry(tester, 'a'), '17');

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('truco-minus-a')));
      await tester.pump();
    }
    await tester.tap(find.text('Guardar corrección'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('truco-total-a'))).data,
      '12',
    );
    expect(repository.commits.single.isEdit, isTrue);
  });
}

String? entry(WidgetTester tester, String side) =>
    tester.widget<Text>(find.byKey(ValueKey('truco-entry-$side'))).data;

ButtonStyleButton button(WidgetTester tester, String kind, String side) {
  return tester.widget<ButtonStyleButton>(find.descendant(
    of: find.byKey(ValueKey('truco-$kind-$side')),
    matching: find.bySubtype<ButtonStyleButton>(),
  ));
}

/// Painter of the matchsticks drawn for one half of one team's tally.
TrucoMatchstickPainter sticks(String side, String half) {
  final finder = find.descendant(
    of: find.byKey(ValueKey('truco-tally-$side')),
    matching: find.byKey(ValueKey('truco-sticks-$half')),
  );
  final paint = finder.evaluate().single.widget as CustomPaint;
  return paint.painter! as TrucoMatchstickPainter;
}
