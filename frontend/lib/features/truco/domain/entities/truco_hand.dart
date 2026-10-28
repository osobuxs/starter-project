import 'package:equatable/equatable.dart';

import 'truco_team.dart';

/// One closed hand: the exact points each team got (may be negative) plus
/// the totals right before it, so the last hand can be reopened.
class TrucoHand extends Equatable {
  final int handNumber;
  final int pointsA;
  final int pointsB;
  final int timestamp;

  /// Totals before this hand was applied. Null on hands that cannot be
  /// corrected.
  final int? scoreABefore;
  final int? scoreBBefore;

  /// Whether closing this hand finished the game, and which team won.
  final bool finishedGame;
  final TrucoTeamSide? winner;

  /// Who dealt this hand; null on hands saved before dealers were tracked.
  final String? dealerId;

  const TrucoHand({
    required this.handNumber,
    required this.pointsA,
    required this.pointsB,
    required this.timestamp,
    this.scoreABefore,
    this.scoreBBefore,
    this.finishedGame = false,
    this.winner,
    this.dealerId,
  });

  bool get canBeEdited => scoreABefore != null && scoreBBefore != null;

  int pointsOf(TrucoTeamSide side) =>
      side == TrucoTeamSide.a ? pointsA : pointsB;

  @override
  List<Object?> get props => [
        handNumber,
        pointsA,
        pointsB,
        timestamp,
        scoreABefore,
        scoreBBefore,
        finishedGame,
        winner,
        dealerId,
      ];
}
