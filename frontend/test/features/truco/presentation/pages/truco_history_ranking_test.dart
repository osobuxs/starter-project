import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_history_tab.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_player_detail_page.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_ranking_tab.dart';

import '../../support/truco_fakes.dart';

const _players = [
  TrucoParticipant(
      id: 'ana', name: 'Ana', totalGamesPlayed: 2, totalGamesWon: 1),
  TrucoParticipant(
      id: 'alma', name: 'Alma', totalGamesPlayed: 2, totalGamesWon: 1),
  TrucoParticipant(
      id: 'beto', name: 'Beto', totalGamesPlayed: 2, totalGamesWon: 1),
  TrucoParticipant(
      id: 'bruno', name: 'Bruno', totalGamesPlayed: 1, totalGamesWon: 1),
];

TrucoGame _game(String id, int date, TrucoTeamSide? winner, int a, int b) {
  return TrucoGame(
    id: id,
    mode: TrucoMode.twoVsTwo,
    targetScore: 30,
    teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['ana', 'alma']),
    teamB: const TrucoTeam(name: 'Ellos', playerIds: ['beto', 'bruno']),
    date: date,
    scoreA: a,
    scoreB: b,
    status: winner == null ? TrucoGameStatus.playing : TrucoGameStatus.finished,
    winner: winner,
  );
}

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeTrucoGameRepository()
      ..games = [
        _game(
            'live', DateTime(2026, 10, 28).millisecondsSinceEpoch, null, 3, 2),
        _game('g2', DateTime(2026, 10, 27).millisecondsSinceEpoch,
            TrucoTeamSide.b, 21, 30),
        _game('g1', DateTime(2026, 10, 26).millisecondsSinceEpoch,
            TrucoTeamSide.a, 30, 12),
      ];
    final multiGameBloc = TrucoMultiGameBloc(repository)
      ..add(const LoadTrucoGamesEvent());
    final participantBloc = TrucoParticipantBloc(
        FakeTrucoParticipantRepository(_players), FakeAuth())
      ..add(const FetchTrucoParticipantsEvent());
    addTearDown(multiGameBloc.close);
    addTearDown(participantBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: multiGameBloc),
          BlocProvider.value(value: participantBloc),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('history lists only finished games with winner and members',
      (tester) async {
    await pump(tester, const TrucoHistoryTab());

    expect(find.text('En juego'), findsNothing);
    expect(find.text('Ganó Ellos'), findsOneWidget);
    expect(find.text('Ganó Nosotros'), findsOneWidget);
    expect(find.text('27/10/2026 · 2 vs 2 · a 30'), findsOneWidget);
    expect(find.textContaining('Ana, Alma'), findsNWidgets(2));
  });

  testWidgets('ranking orders players by wins, win rate and name',
      (tester) async {
    await pump(tester, const TrucoRankingTab());

    final order = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.key! as ValueKey<String>).value)
        .toList();
    expect(order, [
      'truco-rank-bruno',
      'truco-rank-alma',
      'truco-rank-ana',
      'truco-rank-beto',
    ]);
    expect(find.textContaining('Winrate: 100.0%'), findsOneWidget);
  });

  testWidgets('player detail shows totals, partners, opponents and results',
      (tester) async {
    await pump(tester, const TrucoPlayerDetailPage(playerId: 'alma'));

    expect(find.text('Alma'), findsOneWidget); // app bar title
    expect(find.byKey(const ValueKey('truco-player-game-g1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('truco-player-game-live')), findsOneWidget);
    expect(find.textContaining('Compañeros: Ana'), findsNWidgets(3));
    expect(find.textContaining('Rivales: Beto, Bruno'), findsNWidgets(3));
    expect(find.text('Nosotros 30 – 12 Ellos'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget);
  });
}
