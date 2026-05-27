import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

/// Returns true if the dart results in a bust for 501/301 modes.
///
/// Bust conditions (when doubleOut is true):
/// - remainingAfter < 0  (overshoot)
/// - remainingAfter == 1 (can never finish from 1)
/// - remainingAfter == 0 AND multiplier != 2 (must finish on a double)
///   Exception: bull inner (dartPoints == 50, multiplier == 2) counts as double
///
/// When doubleOut is false, only overshoot busts.
bool isBust({
  required int remainingBefore,
  required int dartPoints,
  required int dartMultiplier,
  required bool doubleOut,
}) {
  final remainingAfter = remainingBefore - dartPoints;

  if (remainingAfter < 0) return true;

  if (!doubleOut) return false;

  if (remainingAfter == 1) return true;

  if (remainingAfter == 0) {
    // Double-out rule: must finish on a double (multiplier == 2).
    // Bull inner (50 pts, multiplier 2) counts as a double.
    if (dartMultiplier == 2) return false;
    return true;
  }

  return false;
}

/// Returns true if this dart is a valid checkout (lands exactly on 0
/// without busting).
bool isValidCheckout({
  required int remainingBefore,
  required int dartPoints,
  required int dartMultiplier,
  required bool doubleOut,
}) {
  if (dartPoints != remainingBefore) return false;
  return !isBust(
    remainingBefore: remainingBefore,
    dartPoints: dartPoints,
    dartMultiplier: dartMultiplier,
    doubleOut: doubleOut,
  );
}

/// Subtracts [dartPoints] from [remainingBefore] and returns the result.
/// May return negative — caller is responsible for bust detection.
int nextScoreAfterThrow({
  required int remainingBefore,
  required int dartPoints,
}) {
  return remainingBefore - dartPoints;
}

/// Sums the points from all darts in a turn (including bust darts for
/// display purposes, though the BLoC will revert the full turn on bust).
int turnTotal(List<DardosThrowEntity> dartsInTurn) {
  var total = 0;
  for (final dart in dartsInTurn) {
    total += dart.points;
  }
  return total;
}

/// A turn is complete when:
/// - 3 darts have been thrown (dartIndex == 2 was thrown), OR
/// - any dart in the turn has isBust == true (turn ends immediately on bust)
bool isTurnComplete(List<DardosThrowEntity> dartsInTurn) {
  for (final dart in dartsInTurn) {
    if (dart.isBust) return true;
    if (dart.dartIndex == 2) return true;
  }
  return false;
}

/// Computes the remaining score for [playerId] in a leg, given all throws
/// in the leg (across all players). Bust darts are excluded from subtraction —
/// the score reverts to the start of the bust player's turn (since we only
/// add non-bust darts from [throwsInLeg], which should already reflect the
/// revert semantics from the caller).
///
/// Note: This function only subtracts non-bust darts for the given player.
/// The BLoC is responsible for ensuring bust darts are either excluded or
/// handled at the turn level.
int computeRemainingScore({
  required int startScore,
  required List<DardosThrowEntity> throwsInLeg,
  required String playerId,
}) {
  var remaining = startScore;
  for (final t in throwsInLeg) {
    if (t.playerId != playerId) continue;
    if (t.isBust) continue;
    remaining -= t.points;
  }
  return remaining;
}
