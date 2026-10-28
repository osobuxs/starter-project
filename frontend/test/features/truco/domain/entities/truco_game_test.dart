import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

void main() {
  const game = TrucoGame(
    id: 'g1',
    mode: TrucoMode.twoVsTwo,
    targetScore: 30,
    teamA: TrucoTeam(name: 'Nosotros', playerIds: ['a1', 'a2']),
    teamB: TrucoTeam(name: 'Ellos', playerIds: ['b1', 'b2']),
    date: 1,
  );

  test('a new game starts at zero, playing, on hand 1', () {
    expect(game.scoreA, 0);
    expect(game.scoreB, 0);
    expect(game.status, TrucoGameStatus.playing);
    expect(game.currentHand, 1);
    expect(game.isFinished, isFalse);
  });

  test('exposes team, score and players by side', () {
    final scored = game.copyWith(scoreA: 4, scoreB: 7);

    expect(scored.teamOf(TrucoTeamSide.a).name, 'Nosotros');
    expect(scored.scoreOf(TrucoTeamSide.b), 7);
    expect(scored.allPlayerIds, ['a1', 'a2', 'b1', 'b2']);
  });

  test('the seating order alternates team members', () {
    expect(game.seatingOrder, ['a1', 'b1', 'a2', 'b2']);
  });

  test('games without name, seating or dealer get safe defaults', () {
    expect(game.name, 'Truco');
    expect(game.currentDealerId, 'a1');
  });

  test('stored seating and dealer win over the derived ones', () {
    final custom = game.copyWith(
      name: 'Truco 28/10',
      seatingOrder: ['a2', 'b1', 'a1', 'b2'],
      currentDealerId: 'b1',
    );

    expect(custom.name, 'Truco 28/10');
    expect(custom.seatingOrder, ['a2', 'b1', 'a1', 'b2']);
    expect(custom.currentDealerId, 'b1');
  });

  test('a dealer that is not seated falls back to the first seat', () {
    expect(game.copyWith(currentDealerId: 'zz').currentDealerId, 'a1');
  });

  test('mode maps to players per team and back', () {
    expect(TrucoMode.oneVsOne.playersPerTeam, 1);
    expect(TrucoMode.threeVsThree.playersPerTeam, 3);
    expect(TrucoMode.fromPlayersPerTeam(2), TrucoMode.twoVsTwo);
    expect(TrucoMode.twoVsTwo.label, '2 vs 2');
  });

  test('copyWith can clear the winner', () {
    final finished = game.copyWith(
      status: TrucoGameStatus.finished,
      winner: TrucoTeamSide.a,
    );
    final reopened = finished.copyWith(
      status: TrucoGameStatus.playing,
      clearWinner: true,
    );

    expect(finished.isFinished, isTrue);
    expect(reopened.winner, isNull);
  });

  test('a hand is editable only when it carries the pre-hand snapshot', () {
    const legacy = TrucoHand(
      handNumber: 1,
      pointsA: 1,
      pointsB: 0,
      timestamp: 1,
    );
    const snapshot = TrucoHand(
      handNumber: 1,
      pointsA: 1,
      pointsB: 0,
      timestamp: 1,
      scoreABefore: 0,
      scoreBBefore: 0,
    );

    expect(legacy.canBeEdited, isFalse);
    expect(snapshot.canBeEdited, isTrue);
    expect(snapshot.pointsOf(TrucoTeamSide.a), 1);
  });
}
