import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';

/// Valid Cricket targets.
const List<String> _cricketTargets = [
  '15',
  '16',
  '17',
  '18',
  '19',
  '20',
  'bull',
];

/// Applies [multiplier] marks to [target] for [playerId] and returns a new
/// [CricketMarksState]. Points are NOT computed here — see
/// [computePointsFromOverflow]. Marks accumulate past 3 (overflow is used to
/// determine bonus points).
///
/// Invalid targets (not in 15-20 or bull) result in 0 mark changes.
CricketMarksState computeMarksAfterThrow({
  required CricketMarksState currentState,
  required String playerId,
  required String target,
  required int multiplier,
}) {
  if (!_cricketTargets.contains(target)) {
    return currentState;
  }

  final newMarksByPlayer = <String, Map<String, int>>{};
  for (final pid in currentState.marksByPlayer.keys) {
    newMarksByPlayer[pid] = Map<String, int>.from(currentState.marksByPlayer[pid]!);
  }

  final playerMarks = newMarksByPlayer[playerId];
  if (playerMarks == null) return currentState;

  playerMarks[target] = (playerMarks[target] ?? 0) + multiplier;

  return currentState.copyWith(marksByPlayer: newMarksByPlayer);
}

/// Returns true when EVERY player in [playerMarksOnTarget] has ≥ 3 marks.
bool isTargetClosedByAll(Map<String, int> playerMarksOnTarget) {
  for (final marks in playerMarksOnTarget.values) {
    if (marks < 3) return false;
  }
  return true;
}

/// Computes the cross-points earned by [playerId] from hitting [target] with
/// [multiplierApplied] marks.
///
/// Points are only generated when:
/// 1. The player has already closed (≥ 3 marks) the target BEFORE this throw,
///    OR closes it on this throw with surplus marks.
/// 2. At least one opponent has fewer than 3 marks on this target.
///
/// [playerMarksOnTarget] = marks per player BEFORE this throw.
/// [multiplierApplied] = marks added by this throw.
/// [basePoints] = face value of the target (15-20 or 25 for bull).
///
/// Returns 0 if not applicable.
int computePointsFromOverflow({
  required Map<String, int> playerMarksOnTarget,
  required String playerId,
  required String target,
  required int multiplierApplied,
  required int basePoints,
}) {
  final marksBefore = playerMarksOnTarget[playerId] ?? 0;
  final marksAfter = marksBefore + multiplierApplied;

  // Must have at least 3 marks after the throw to have closed the target.
  if (marksAfter < 3) return 0;

  // Surplus marks beyond the 3 needed to close.
  final surplusMarks = marksAfter - 3;
  if (surplusMarks <= 0) return 0;

  // Check if the number is dead (all opponents have closed it).
  final allClosed = isTargetClosedByAll(playerMarksOnTarget);
  if (allClosed) return 0;

  // Check if at least one opponent has not closed this target.
  var hasOpenOpponent = false;
  for (final entry in playerMarksOnTarget.entries) {
    if (entry.key == playerId) continue;
    if (entry.value < 3) {
      hasOpenOpponent = true;
      break;
    }
  }
  if (!hasOpenOpponent) return 0;

  return surplusMarks * basePoints;
}

/// Returns true if [playerId] has won the leg in Cricket.
///
/// Win condition: player closed ALL 7 targets (≥ 3 marks each) AND their
/// points ≥ every opponent's points.
bool isCricketWinner({
  required CricketMarksState state,
  required String playerId,
  required List<String> playerIds,
}) {
  final playerMarks = state.marksByPlayer[playerId];
  if (playerMarks == null) return false;

  // Check all 7 targets are closed.
  for (final target in CricketMarksState.cricketTargets) {
    if ((playerMarks[target] ?? 0) < 3) return false;
  }

  // Check player has >= all opponents' points.
  final playerPoints = state.pointsByPlayer[playerId] ?? 0;
  for (final pid in playerIds) {
    if (pid == playerId) continue;
    if (playerPoints < (state.pointsByPlayer[pid] ?? 0)) return false;
  }

  return true;
}
