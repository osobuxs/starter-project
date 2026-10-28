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
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/truco_route_names.dart';

import '../../support/truco_fakes.dart';

void main() {
  Future<List<String?>> pump(WidgetTester tester, {required bool admin}) async {
    final opened = <String?>[];
    final gameRepository = FakeTrucoGameRepository()
      ..games = [
        TrucoGame(
          id: 'g1',
          mode: TrucoMode.oneVsOne,
          targetScore: 18,
          teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['a']),
          teamB: const TrucoTeam(name: 'Ellos', playerIds: ['b']),
          date: DateTime(2026, 10, 28).millisecondsSinceEpoch,
          scoreA: 7,
        ),
      ];
    final multiGameBloc = TrucoMultiGameBloc(gameRepository)
      ..add(const LoadTrucoGamesEvent());
    final participantBloc = TrucoParticipantBloc(
      FakeTrucoParticipantRepository(const [
        TrucoParticipant(id: 'a', name: 'Ana'),
        TrucoParticipant(id: 'b', name: 'Beto'),
      ]),
      FakeAuth(email: admin ? 'lfexevega95@gmail.com' : null),
    )
      ..add(const CheckTrucoAdminStatusEvent())
      ..add(const FetchTrucoParticipantsEvent());
    addTearDown(multiGameBloc.close);
    addTearDown(participantBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: multiGameBloc),
          BlocProvider.value(value: participantBloc),
        ],
        child: MaterialApp(
          home: const TrucoIniciarTab(),
          onGenerateRoute: (settings) {
            opened.add('${settings.name}:${settings.arguments}');
            return MaterialPageRoute(builder: (_) => const Text('destino'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('lists games in progress and opens the board', (tester) async {
    final opened = await pump(tester, admin: false);

    expect(find.text('28/10/2026 · 1 vs 1 · a 18'), findsOneWidget);
    expect(find.text('En juego'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Nueva partida'), findsNothing);

    await tester.tap(find.text('En juego'));
    await tester.pumpAndSettle();
    expect(opened, ['${TrucoRouteNames.play}:g1']);
  });

  testWidgets('admin can start a new game', (tester) async {
    final opened = await pump(tester, admin: true);

    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    expect(opened, ['${TrucoRouteNames.create}:null']);
  });
}
