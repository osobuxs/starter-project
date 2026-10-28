import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_players_tab.dart';

import '../../support/truco_fakes.dart';

void main() {
  Future<FakeTrucoParticipantRepository> pump(
    WidgetTester tester, {
    required String? email,
  }) async {
    final repository = FakeTrucoParticipantRepository(const [
      TrucoParticipant(id: 'p1', name: 'Ana', totalGamesPlayed: 3),
    ]);
    final bloc = TrucoParticipantBloc(repository, FakeAuth(email: email))
      ..add(const CheckTrucoAdminStatusEvent())
      ..add(const FetchTrucoParticipantsEvent());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: TrucoPlayersTab()),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('viewers see players but cannot manage them', (tester) async {
    await pump(tester, email: null);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.textContaining('Jugadas: 3'), findsOneWidget);
    expect(find.text('Agregar jugador'), findsNothing);
    expect(find.byTooltip('Eliminar'), findsNothing);
  });

  testWidgets('admin adds a player from the dialog', (tester) async {
    final repository = await pump(tester, email: 'lfexevega95@gmail.com');

    await tester.tap(find.text('Agregar jugador'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Beto');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.players.map((p) => p.name), ['Ana', 'Beto']);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Jugador agregado'), findsOneWidget);
  });
}
