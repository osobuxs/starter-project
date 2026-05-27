import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_cricket_rules.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_score_rules.dart';

/// Returns the starter player for leg at [globalLegIndex] (0-based).
/// Rotation: `starterOrder[globalLegIndex % starterOrder.length]`
String nextStarter({
  required List<String> starterOrder,
  required int globalLegIndex,
}) {
  return starterOrder[globalLegIndex % starterOrder.length];
}

/// Returns true when a leg is over (some player has won it).
///
/// For '501'/'301': a player reached remainingScore == 0 with a valid checkout.
/// For 'cricket': a player has closed all 7 targets AND points >= all opponents.
bool isLegOver({
  required String mode,
  required int legStartScore,
  required List<DardosThrowEntity> legThrows,
  required List<String> playerIds,
  required bool doubleOut,
}) {
  return legWinner(
        mode: mode,
        legStartScore: legStartScore,
        legThrows: legThrows,
        playerIds: playerIds,
        doubleOut: doubleOut,
      ) !=
      null;
}

/// Returns the playerId of the leg winner, or null if no one has won yet.
///
/// For 501/301: the winner is the first player whose remainingScore == 0
/// (using computeRemainingScore) AND whose last non-bust dart was a valid
/// checkout (remainingAfter == 0, not a bust).
///
/// For cricket: delegates to [isCricketWinner] after replaying marks.
String? legWinner({
  required String mode,
  required int legStartScore,
  required List<DardosThrowEntity> legThrows,
  required List<String> playerIds,
  required bool doubleOut,
}) {
  if (mode == 'cricket') {
    return _cricketLegWinner(legThrows: legThrows, playerIds: playerIds);
  }
  return _countdownLegWinner(
    legStartScore: legStartScore,
    legThrows: legThrows,
    playerIds: playerIds,
    doubleOut: doubleOut,
  );
}

String? _countdownLegWinner({
  required int legStartScore,
  required List<DardosThrowEntity> legThrows,
  required List<String> playerIds,
  required bool doubleOut,
}) {
  // A leg ends when a throw lands at remainingAfter == 0 with a valid checkout.
  // We scan throws in order and return the first player to reach 0 validly.
  for (final t in legThrows) {
    if (t.isBust) continue;
    if (t.remainingAfter != 0) continue;

    // This dart landed at 0. Verify it's a valid checkout.
    // remainingBefore = points + remainingAfter = points + 0 = points
    if (isValidCheckout(
      remainingBefore: t.points,
      dartPoints: t.points,
      dartMultiplier: t.multiplier,
      doubleOut: doubleOut,
    )) {
      return t.playerId;
    }
  }
  return null;
}

String? _cricketLegWinner({
  required List<DardosThrowEntity> legThrows,
  required List<String> playerIds,
}) {
  // Replay all cricket throws to build the final CricketMarksState.
  var state = CricketMarksState.empty(playerIds);

  for (final t in legThrows) {
    final target = t.cricketTarget;
    if (target == null) continue;

    // Determine base points for overflow computation.
    final basePoints = target == 'bull' ? 25 : (int.tryParse(target) ?? 0);

    // Compute overflow points before updating marks.
    final marksForTarget = <String, int>{};
    for (final pid in playerIds) {
      marksForTarget[pid] = state.marksByPlayer[pid]?[target] ?? 0;
    }
    final pointsEarned = computePointsFromOverflow(
      playerMarksOnTarget: marksForTarget,
      playerId: t.playerId,
      target: target,
      multiplierApplied: t.multiplier,
      basePoints: basePoints,
    );

    // Update marks.
    state = computeMarksAfterThrow(
      currentState: state,
      playerId: t.playerId,
      target: target,
      multiplier: t.multiplier,
    );

    // Update points.
    if (pointsEarned > 0) {
      final newPoints = Map<String, int>.from(state.pointsByPlayer);
      newPoints[t.playerId] = (newPoints[t.playerId] ?? 0) + pointsEarned;
      state = state.copyWith(pointsByPlayer: newPoints);
    }
  }

  // Check each player for win condition.
  for (final pid in playerIds) {
    if (isCricketWinner(state: state, playerId: pid, playerIds: playerIds)) {
      return pid;
    }
  }
  return null;
}

/// Returns true when a set is over (some player has won a majority of legs).
///
/// A player wins the set when they have won more than [legsPerSet] / 2 legs
/// (i.e., ceil([legsPerSet] / 2)).
bool isSetOver({
  required int legsPerSet,
  required List<String?> legWinnersInSet,
}) {
  return setWinner(legWinnersInSet) != null;
}

/// Returns the winner of a set (player with majority legs), or null if
/// no majority yet.
String? setWinner(List<String?> legWinnersInSet) {
  return _majority(legWinnersInSet);
}

/// Returns true when a game is over (some player has won a majority of sets).
bool isGameOver({
  required int setsPerGame,
  required List<String?> setWinners,
}) {
  return gameWinner(setWinners) != null;
}

/// Returns the winner of the game (player with majority sets), or null.
String? gameWinner(List<String?> setWinners) {
  return _majority(setWinners);
}

/// Returns the element that appears more than half the time in [items],
/// or null if no majority.
String? _majority(List<String?> items) {
  final counts = <String, int>{};
  for (final item in items) {
    if (item == null) continue;
    counts[item] = (counts[item] ?? 0) + 1;
  }

  final total = items.length;
  final threshold = total ~/ 2 + 1; // strict majority (> half)

  for (final entry in counts.entries) {
    if (entry.value >= threshold) return entry.key;
  }
  return null;
}
