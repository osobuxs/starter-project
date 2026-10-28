import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_state.dart';

import '../../support/truco_fakes.dart';

const _newGame = TrucoGame(
  id: 'g1',
  mode: TrucoMode.oneVsOne,
  targetScore: 18,
  teamA: TrucoTeam(name: 'Nosotros', playerIds: ['a1']),
  teamB: TrucoTeam(name: 'Ellos', playerIds: ['b1']),
  date: 1,
);

void main() {
  late FakeTrucoGameRepository repository;
  late DateTime now;

  setUp(() {
    repository = FakeTrucoGameRepository();
    now = DateTime.fromMillisecondsSinceEpoch(1000000);
  });

  Future<TrucoGameBloc> loaded(TrucoGame game) async {
    repository.game = game;
    final bloc = TrucoGameBloc(repository: repository, now: () => now)
      ..add(const LoadTrucoGameEvent('g1'));
    addTearDown(bloc.close);
    await pumpEventQueue();
    return bloc;
  }

  Future<void> enter(TrucoGameBloc bloc, int a, int b) async {
    bloc
      ..add(SetTrucoHandPointsEvent(side: TrucoTeamSide.a, points: a))
      ..add(SetTrucoHandPointsEvent(side: TrucoTeamSide.b, points: b));
    await pumpEventQueue();
  }

  Future<void> confirm(TrucoGameBloc bloc, int a, int b) async {
    await enter(bloc, a, b);
    bloc.add(const ConfirmTrucoHandEvent());
    await pumpEventQueue();
  }

  test('loads the game', () async {
    final bloc = await loaded(_newGame);

    expect(bloc.state.status, TrucoGameBlocStatus.loaded);
    expect(bloc.state.game, _newGame);
  });

  test('confirming a hand updates totals locally and commits one batch',
      () async {
    final bloc = await loaded(_newGame);
    repository.commitResult = Completer();

    await confirm(bloc, 3, 0);

    // Board updated before the write resolves.
    expect(bloc.state.status, TrucoGameBlocStatus.handConfirmed);
    expect(bloc.state.game!.scoreA, 3);
    expect(bloc.state.game!.scoreB, 0);
    expect(bloc.state.game!.currentHand, 2);
    expect(bloc.state.entryA, 0);
    expect(bloc.state.entryB, 0);

    final commit = repository.commits.single;
    expect(commit.hand.pointsA, 3);
    expect(commit.hand.pointsB, 0);
    expect(commit.hand.scoreABefore, 0);
    expect(commit.hand.timestamp, now.millisecondsSinceEpoch);
    expect(commit.scoreA, 3);
    expect(commit.nextHandNumber, 2);
    expect(commit.winner, isNull);
    expect(commit.teamAPlayerIds, ['a1']);
    repository.commitResult!.complete(const DataSuccess(null));
  });

  test('negative entries are clamped to zero', () async {
    final bloc = await loaded(_newGame);

    await enter(bloc, -3, -1);

    expect(bloc.state.entryA, 0);
    expect(bloc.state.entryB, 0);
  });

  test('an entry cannot exceed the points the team needs to win', () async {
    final bloc =
        await loaded(_newGame.copyWith(scoreA: 16, scoreB: 5, currentHand: 4));

    await enter(bloc, 9, 30);

    expect(bloc.state.entryA, 2);
    expect(bloc.state.entryB, 13);
  });

  test('a hand with no points is rejected', () async {
    final bloc = await loaded(_newGame);

    bloc.add(const ConfirmTrucoHandEvent());
    await pumpEventQueue();

    expect(bloc.state.status, TrucoGameBlocStatus.error);
    expect(bloc.state.error, 'Ingrese los puntos de la mano.');
    expect(repository.commits, isEmpty);
  });

  test('reaching the target finishes the game with that team as winner',
      () async {
    final bloc = await loaded(_newGame.copyWith(scoreA: 16, currentHand: 4));

    await confirm(bloc, 4, 0);

    expect(bloc.state.status, TrucoGameBlocStatus.gameFinished);
    expect(bloc.state.game!.isFinished, isTrue);
    expect(bloc.state.game!.winner, TrucoTeamSide.a);
    expect(bloc.state.game!.scoreA, 18);
    expect(repository.commits.single.winner, TrucoTeamSide.a);
    expect(repository.commits.single.hand.finishedGame, isTrue);
  });

  test('both teams reaching the target with the same total is an error',
      () async {
    final bloc =
        await loaded(_newGame.copyWith(scoreA: 16, scoreB: 16, currentHand: 4));

    await confirm(bloc, 2, 2);

    expect(bloc.state.status, TrucoGameBlocStatus.error);
    expect(bloc.state.error, contains('mismo total'));
    expect(bloc.state.game!.isFinished, isFalse);
    expect(bloc.state.entryA, 2);
    expect(repository.commits, isEmpty);
  });

  test('a failed commit keeps the local board and reports the error', () async {
    final bloc = await loaded(_newGame);
    repository.commitResult = Completer()
      ..complete(DataFailed(Exception('offline')));

    await confirm(bloc, 2, 0);

    expect(bloc.state.status, TrucoGameBlocStatus.error);
    expect(bloc.state.error, startsWith('No se pudo guardar la mano'));
    expect(bloc.state.game!.scoreA, 2);
  });

  test('remote updates replace the board for viewers', () async {
    final bloc = await loaded(_newGame);

    repository.remote.add(DataSuccess(_newGame.copyWith(scoreB: 5)));
    await pumpEventQueue();

    expect(bloc.state.game!.scoreB, 5);
  });

  test('a remote finish moves the viewer to the finished state', () async {
    final bloc = await loaded(_newGame);

    repository.remote.add(DataSuccess(_newGame.copyWith(
      scoreA: 18,
      status: TrucoGameStatus.finished,
      winner: TrucoTeamSide.a,
    )));
    await pumpEventQueue();

    expect(bloc.state.status, TrucoGameBlocStatus.gameFinished);
  });

  group('correct last hand', () {
    final afterOneHand = _newGame.copyWith(
      scoreA: 3,
      scoreB: 1,
      currentHand: 2,
      hands: [
        TrucoHand(
          handNumber: 1,
          pointsA: 3,
          pointsB: 1,
          timestamp: 1000000,
          scoreABefore: 0,
          scoreBBefore: 0,
        ),
      ],
    );

    test('reopens the last hand with its points and pre-hand totals', () async {
      final bloc = await loaded(afterOneHand);

      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();

      expect(bloc.state.isEditingHand, isTrue);
      expect(bloc.state.editingHandNumber, 1);
      expect(bloc.state.game!.scoreA, 0);
      expect(bloc.state.game!.hands, isEmpty);
      expect(bloc.state.entryA, 3);
      expect(bloc.state.entryB, 1);
    });

    test('saving the correction overwrites the hand as an edit', () async {
      final bloc = await loaded(afterOneHand);
      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();

      await confirm(bloc, 5, 1);

      expect(bloc.state.isEditingHand, isFalse);
      expect(bloc.state.game!.scoreA, 5);
      expect(bloc.state.game!.hands.single.pointsA, 5);
      final commit = repository.commits.single;
      expect(commit.isEdit, isTrue);
      expect(commit.hand.handNumber, 1);
      expect(commit.hand.timestamp, 1000000);
      expect(commit.revertWinner, isNull);
    });

    test('cancel restores the board, applying remote changes seen meanwhile',
        () async {
      final bloc = await loaded(afterOneHand);
      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();

      repository.remote.add(DataSuccess(afterOneHand.copyWith(scoreB: 2)));
      await pumpEventQueue();
      expect(bloc.state.game!.scoreB, 0, reason: 'buffered while editing');

      bloc.add(const CancelEditLastTrucoHandEvent());
      await pumpEventQueue();

      expect(bloc.state.isEditingHand, isFalse);
      expect(bloc.state.game!.scoreB, 2);
    });

    final finished = _newGame.copyWith(
      scoreA: 18,
      scoreB: 4,
      currentHand: 3,
      status: TrucoGameStatus.finished,
      winner: TrucoTeamSide.a,
      hands: [
        const TrucoHand(
          handNumber: 1,
          pointsA: 14,
          pointsB: 4,
          timestamp: 1,
          scoreABefore: 0,
          scoreBBefore: 0,
        ),
        const TrucoHand(
          handNumber: 2,
          pointsA: 4,
          pointsB: 0,
          timestamp: 1000000,
          scoreABefore: 14,
          scoreBBefore: 4,
          finishedGame: true,
          winner: TrucoTeamSide.a,
        ),
      ],
    );

    test('a finished game is correctable within 10 minutes and reopens',
        () async {
      now = now.add(const Duration(minutes: 9));
      final bloc = await loaded(finished);

      expect(bloc.state.editableLastHandAt(now), isNotNull);
      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();
      expect(bloc.state.game!.isFinished, isFalse);

      await confirm(bloc, 2, 0);

      final commit = repository.commits.single;
      expect(commit.isEdit, isTrue);
      expect(commit.winner, isNull);
      expect(commit.revertWinner, TrucoTeamSide.a);
      expect(bloc.state.game!.isFinished, isFalse);
      expect(bloc.state.game!.scoreA, 16);
    });

    test('after 10 minutes the finished game is no longer correctable',
        () async {
      now = now.add(const Duration(minutes: 11));
      final bloc = await loaded(finished);

      expect(bloc.state.editableLastHandAt(now), isNull);
      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();
      expect(bloc.state.isEditingHand, isFalse);
    });

    test('hands without a snapshot cannot be corrected', () async {
      final bloc = await loaded(_newGame.copyWith(
        currentHand: 2,
        hands: const [
          TrucoHand(handNumber: 1, pointsA: 1, pointsB: 0, timestamp: 1),
        ],
      ));

      expect(bloc.state.editableLastHandAt(now), isNull);
    });
  });
  group('dealer rotation', () {
    const table = TrucoGame(
      id: 'g1',
      name: 'Truco 28/10',
      mode: TrucoMode.twoVsTwo,
      targetScore: 30,
      teamA: TrucoTeam(name: 'Nosotros', playerIds: ['a1', 'a2']),
      teamB: TrucoTeam(name: 'Ellos', playerIds: ['b1', 'b2']),
      seatingOrder: ['a1', 'b1', 'a2', 'b2'],
      currentDealerId: 'a2',
      date: 1,
    );

    test('a confirmed hand stores its dealer and passes the deck one seat',
        () async {
      final bloc = await loaded(table);

      await confirm(bloc, 1, 0);

      expect(bloc.state.game!.hands.single.dealerId, 'a2');
      expect(bloc.state.game!.currentDealerId, 'b2');
      final commit = repository.commits.single;
      expect(commit.hand.dealerId, 'a2');
      expect(commit.nextDealerId, 'b2');
    });

    test('the deck wraps from the last seat back to the first', () async {
      final bloc = await loaded(table);

      await confirm(bloc, 1, 0);
      await confirm(bloc, 0, 1);

      expect(bloc.state.game!.currentDealerId, 'a1');
      expect(repository.commits.last.hand.dealerId, 'b2');
      expect(repository.commits.last.nextDealerId, 'a1');
    });

    test('correcting the last hand restores its dealer and recomputes on save',
        () async {
      final bloc = await loaded(table);
      await confirm(bloc, 1, 0);
      repository.commits.clear();

      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();
      expect(bloc.state.game!.currentDealerId, 'a2');

      await confirm(bloc, 2, 0);

      expect(bloc.state.game!.currentDealerId, 'b2');
      final commit = repository.commits.single;
      expect(commit.hand.dealerId, 'a2');
      expect(commit.nextDealerId, 'b2');
    });

    test('cancelling a correction keeps the next dealer', () async {
      final bloc = await loaded(table);
      await confirm(bloc, 1, 0);

      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();
      bloc.add(const CancelEditLastTrucoHandEvent());
      await pumpEventQueue();

      expect(bloc.state.game!.currentDealerId, 'b2');
    });

    test('a legacy hand without dealer reopens on the previous seat', () async {
      final bloc = await loaded(table.copyWith(
        currentDealerId: 'b1',
        scoreA: 1,
        currentHand: 2,
        hands: [
          TrucoHand(
            handNumber: 1,
            pointsA: 1,
            pointsB: 0,
            timestamp: 1000000,
            scoreABefore: 0,
            scoreBBefore: 0,
          ),
        ],
      ));

      bloc.add(const StartEditLastTrucoHandEvent());
      await pumpEventQueue();

      expect(bloc.state.game!.currentDealerId, 'a1');
    });
  });
}
