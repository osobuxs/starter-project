import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_cubit.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_state.dart';

import '../../support/truco_fakes.dart';

void main() {
  late FakeTrucoGameRepository repository;

  setUp(() => repository = FakeTrucoGameRepository());

  TrucoCreateGameCubit build() => TrucoCreateGameCubit(
        repository,
        now: () => DateTime(2026, 10, 28),
      );

  test('starts as a 2 vs 2 to 30 with default team names', () {
    final state = build().state;

    expect(state.mode, TrucoMode.twoVsTwo);
    expect(state.targetScore, 30);
    expect(state.teamA.name, 'Nosotros');
    expect(state.teamB.name, 'Ellos');
    expect(state.canSubmit, isFalse);
  });

  test('suggests a dated game name that can be changed', () {
    final cubit = build();
    expect(cubit.state.name, 'Truco 28/10');

    cubit.rename('Revancha');
    expect(cubit.state.name, 'Revancha');
  });

  test('an empty name blocks the game', () {
    final cubit = build()
      ..selectMode(TrucoMode.oneVsOne)
      ..togglePlayer(TrucoTeamSide.a, 'a1')
      ..togglePlayer(TrucoTeamSide.b, 'b1')
      ..rename('   ');

    expect(cubit.state.validationError, 'La partida necesita un nombre.');
    expect(cubit.state.canSubmit, isFalse);
  });

  test('the first dealer defaults to A1 and can be any seated player', () {
    final cubit = build()
      ..togglePlayer(TrucoTeamSide.a, 'a1')
      ..togglePlayer(TrucoTeamSide.a, 'a2')
      ..togglePlayer(TrucoTeamSide.b, 'b1')
      ..togglePlayer(TrucoTeamSide.b, 'b2');
    expect(cubit.state.firstDealerId, 'a1');

    cubit.selectFirstDealer('b2');
    expect(cubit.state.firstDealerId, 'b2');

    cubit.selectFirstDealer('zz');
    expect(cubit.state.firstDealerId, 'b2', reason: 'not seated: ignored');

    cubit.togglePlayer(TrucoTeamSide.b, 'b2');
    expect(cubit.state.firstDealerId, 'a1', reason: 'dealer left the table');
  });

  test('toggling adds players until the team is full', () {
    final cubit = build()
      ..togglePlayer(TrucoTeamSide.a, 'a1')
      ..togglePlayer(TrucoTeamSide.a, 'a2')
      ..togglePlayer(TrucoTeamSide.a, 'a3');

    expect(cubit.state.teamA.playerIds, ['a1', 'a2']);

    cubit.togglePlayer(TrucoTeamSide.a, 'a1');
    expect(cubit.state.teamA.playerIds, ['a2']);
  });

  test('picking a player for the other team moves them', () {
    final cubit = build()
      ..togglePlayer(TrucoTeamSide.a, 'p1')
      ..togglePlayer(TrucoTeamSide.b, 'p1');

    expect(cubit.state.teamA.playerIds, isEmpty);
    expect(cubit.state.teamB.playerIds, ['p1']);
  });

  test('a smaller mode trims the teams to fit', () {
    final cubit = build()
      ..togglePlayer(TrucoTeamSide.a, 'a1')
      ..togglePlayer(TrucoTeamSide.a, 'a2')
      ..selectMode(TrucoMode.oneVsOne);

    expect(cubit.state.teamA.playerIds, ['a1']);
  });

  test('players can be reordered within a team to match the seats', () {
    final cubit = build()
      ..selectMode(TrucoMode.threeVsThree)
      ..togglePlayer(TrucoTeamSide.b, 'b1')
      ..togglePlayer(TrucoTeamSide.b, 'b2')
      ..togglePlayer(TrucoTeamSide.b, 'b3')
      ..movePlayer(TrucoTeamSide.b, 2, 0);

    expect(cubit.state.teamB.playerIds, ['b3', 'b1', 'b2']);
  });

  test('the seating alternates teams', () {
    final cubit = build()
      ..togglePlayer(TrucoTeamSide.a, 'a1')
      ..togglePlayer(TrucoTeamSide.a, 'a2')
      ..togglePlayer(TrucoTeamSide.b, 'b1')
      ..togglePlayer(TrucoTeamSide.b, 'b2');

    expect(cubit.state.seatingOrder, ['a1', 'b1', 'a2', 'b2']);
    expect(cubit.state.canSubmit, isTrue);
  });

  blocTest<TrucoCreateGameCubit, TrucoCreateGameState>(
    'submitting an incomplete table shows the validation error',
    build: build,
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<TrucoCreateGameState>()
          .having((s) => s.status, 'status', TrucoCreateGameStatus.error)
          .having(
            (s) => s.error,
            'error',
            'Cada equipo debe tener 2 jugadores.',
          ),
    ],
    verify: (_) => expect(repository.game, isNull),
  );

  blocTest<TrucoCreateGameCubit, TrucoCreateGameState>(
    'submitting a valid table creates the game with trimmed names',
    build: build,
    act: (cubit) async {
      cubit
        ..selectMode(TrucoMode.oneVsOne)
        ..selectTarget(18)
        ..renameTeam(TrucoTeamSide.a, '  Los de acá ')
        ..togglePlayer(TrucoTeamSide.a, 'a1')
        ..togglePlayer(TrucoTeamSide.b, 'b1')
        ..rename('  Final  ')
        ..selectFirstDealer('b1');
      await cubit.submit();
    },
    skip: 7,
    expect: () => [
      isA<TrucoCreateGameState>()
          .having((s) => s.status, 'status', TrucoCreateGameStatus.submitting),
      isA<TrucoCreateGameState>()
          .having((s) => s.status, 'status', TrucoCreateGameStatus.created)
          .having((s) => s.createdGame?.id, 'game id', 'created'),
    ],
    verify: (_) {
      final game = repository.game!;
      expect(game.mode, TrucoMode.oneVsOne);
      expect(game.targetScore, 18);
      expect(
          game.teamA, const TrucoTeam(name: 'Los de acá', playerIds: ['a1']));
      expect(game.teamB, const TrucoTeam(name: 'Ellos', playerIds: ['b1']));
      expect(game.name, 'Final');
      expect(game.seatingOrder, ['a1', 'b1']);
      expect(game.currentDealerId, 'b1');
    },
  );

  blocTest<TrucoCreateGameCubit, TrucoCreateGameState>(
    'a failed save reports an error and keeps the form',
    build: () {
      repository.failCreate = true;
      return build();
    },
    act: (cubit) async {
      cubit
        ..selectMode(TrucoMode.oneVsOne)
        ..togglePlayer(TrucoTeamSide.a, 'a1')
        ..togglePlayer(TrucoTeamSide.b, 'b1');
      await cubit.submit();
    },
    skip: 4,
    expect: () => [
      isA<TrucoCreateGameState>()
          .having((s) => s.status, 'status', TrucoCreateGameStatus.error)
          .having((s) => s.teamA.playerIds, 'team A', ['a1']),
    ],
  );
}
