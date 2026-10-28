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

  Future<void> pump(WidgetTester tester, {required bool admin}) async {
    tester.view.physicalSize = const Size(1000, 2800);
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

  testWidgets('admin confirms a hand and the board updates at once',
      (tester) async {
    await pump(tester, admin: true);

    await tester.enterText(find.byKey(const ValueKey('truco-entry-a')), '2');
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
    // Entry fields are cleared for the next hand.
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('truco-entry-a')))
          .controller!
          .text,
      '',
    );
  });

  testWidgets('admin corrects the last hand with the pencil', (tester) async {
    await pump(tester, admin: true);

    await tester.tap(find.byTooltip('Corregir última mano'));
    await tester.pumpAndSettle();

    expect(find.text('Editando mano 1'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('truco-entry-a')))
          .controller!
          .text,
      '17',
    );

    await tester.enterText(find.byKey(const ValueKey('truco-entry-a')), '12');
    await tester.tap(find.text('Guardar corrección'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('truco-total-a'))).data,
      '12',
    );
    expect(repository.commits.single.isEdit, isTrue);
  });
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
