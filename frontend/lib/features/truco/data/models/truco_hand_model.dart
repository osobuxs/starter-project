import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

/// Firestore mapping for `truco_games/{gameId}/hands/{handNumber}`.
class TrucoHandModel {
  const TrucoHandModel._();

  static TrucoHand fromFirestore(Map<String, dynamic> json) {
    return TrucoHand(
      handNumber: json['handNumber'] as int,
      pointsA: json['pointsA'] as int? ?? 0,
      pointsB: json['pointsB'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? 0,
      scoreABefore: json['scoreABefore'] as int?,
      scoreBBefore: json['scoreBBefore'] as int?,
      finishedGame: json['finishedGame'] as bool? ?? false,
      winner: TrucoTeamSide.fromKey(json['winnerTeam']),
    );
  }

  static Map<String, dynamic> toJson(TrucoHand hand) {
    return {
      'handNumber': hand.handNumber,
      'pointsA': hand.pointsA,
      'pointsB': hand.pointsB,
      'timestamp': hand.timestamp,
      if (hand.scoreABefore != null) 'scoreABefore': hand.scoreABefore,
      if (hand.scoreBBefore != null) 'scoreBBefore': hand.scoreBBefore,
      'finishedGame': hand.finishedGame,
      'winnerTeam': hand.winner?.key,
    };
  }
}
