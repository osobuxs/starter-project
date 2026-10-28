import 'package:equatable/equatable.dart';

import 'truco_hand.dart';
import 'truco_team.dart';

/// Everything persisted atomically when a hand is closed: the hand, the new
/// totals and, when the game finishes, the winner and player stats.
///
/// When [isEdit] is true the hand document is overwritten and status/winner
/// are always rewritten; [revertWinner] is the winner the original hand
/// produced, whose stats are undone first.
class TrucoHandCommit extends Equatable {
  final String gameId;
  final TrucoHand hand;
  final List<String> teamAPlayerIds;
  final List<String> teamBPlayerIds;
  final int scoreA;
  final int scoreB;
  final int nextHandNumber;
  final TrucoTeamSide? winner;
  final bool isEdit;
  final TrucoTeamSide? revertWinner;

  const TrucoHandCommit({
    required this.gameId,
    required this.hand,
    required this.teamAPlayerIds,
    required this.teamBPlayerIds,
    required this.scoreA,
    required this.scoreB,
    required this.nextHandNumber,
    this.winner,
    this.isEdit = false,
    this.revertWinner,
  });

  List<String> playersOf(TrucoTeamSide side) =>
      side == TrucoTeamSide.a ? teamAPlayerIds : teamBPlayerIds;

  @override
  List<Object?> get props => [
        gameId,
        hand,
        teamAPlayerIds,
        teamBPlayerIds,
        scoreA,
        scoreB,
        nextHandNumber,
        winner,
        isEdit,
        revertWinner,
      ];
}
