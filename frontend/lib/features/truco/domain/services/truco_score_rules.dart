import 'package:equatable/equatable.dart';

import '../entities/truco_team.dart';

/// Points that make up "las malas" (and, again, "las buenas").
int trucoHalfOf(int targetScore) => targetScore ~/ 2;

/// Whether a total is already in "las buenas".
bool isTrucoBuenas(int points, int targetScore) =>
    points > trucoHalfOf(targetScore);

/// Result of applying one hand to the current totals.
class TrucoHandOutcome extends Equatable {
  final int scoreA;
  final int scoreB;
  final TrucoTeamSide? winner;

  /// Both teams reached the target with the same raw total: the hand cannot
  /// be closed as entered.
  final bool isUnresolvedTie;

  const TrucoHandOutcome({
    required this.scoreA,
    required this.scoreB,
    this.winner,
    this.isUnresolvedTie = false,
  });

  @override
  List<Object?> get props => [scoreA, scoreB, winner, isUnresolvedTie];
}

/// Adds the hand points to each team, clamping totals to [0, targetScore].
/// A team that reaches the target wins; if both do, the higher raw total
/// (before clamping) wins and an exact tie is left unresolved.
TrucoHandOutcome applyTrucoHand({
  required int scoreA,
  required int scoreB,
  required int pointsA,
  required int pointsB,
  required int targetScore,
}) {
  final rawA = scoreA + pointsA;
  final rawB = scoreB + pointsB;
  final reachedA = rawA >= targetScore;
  final reachedB = rawB >= targetScore;

  TrucoTeamSide? winner;
  var tie = false;
  if (reachedA && reachedB) {
    if (rawA > rawB) {
      winner = TrucoTeamSide.a;
    } else if (rawB > rawA) {
      winner = TrucoTeamSide.b;
    } else {
      tie = true;
    }
  } else if (reachedA) {
    winner = TrucoTeamSide.a;
  } else if (reachedB) {
    winner = TrucoTeamSide.b;
  }

  return TrucoHandOutcome(
    scoreA: rawA.clamp(0, targetScore),
    scoreB: rawB.clamp(0, targetScore),
    winner: winner,
    isUnresolvedTie: tie,
  );
}

/// How a total is drawn as matchsticks: groups of up to five (a square of
/// four plus a diagonal), split into malas and buenas.
class TrucoMatchstickLayout extends Equatable {
  final List<int> malas;
  final List<int> buenas;

  const TrucoMatchstickLayout({required this.malas, required this.buenas});

  @override
  List<Object?> get props => [malas, buenas];
}

TrucoMatchstickLayout trucoMatchstickLayout({
  required int points,
  required int targetScore,
}) {
  final half = trucoHalfOf(targetScore);
  final clamped = points.clamp(0, targetScore);
  final malas = clamped > half ? half : clamped;
  final buenas = clamped - malas;
  return TrucoMatchstickLayout(
    malas: _groupsOfFive(malas),
    buenas: _groupsOfFive(buenas),
  );
}

List<int> _groupsOfFive(int count) {
  return [
    for (var remaining = count; remaining > 0; remaining -= 5)
      remaining >= 5 ? 5 : remaining,
  ];
}

/// Players around the table alternating teams: A1, B1, A2, B2, ...
List<String> trucoSeatingOrder(List<String> teamA, List<String> teamB) {
  final seats = <String>[];
  final length = teamA.length > teamB.length ? teamA.length : teamB.length;
  for (var i = 0; i < length; i++) {
    if (i < teamA.length) seats.add(teamA[i]);
    if (i < teamB.length) seats.add(teamB[i]);
  }
  return seats;
}
