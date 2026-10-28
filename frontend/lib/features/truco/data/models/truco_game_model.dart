import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

/// Firestore mapping for `truco_games/{gameId}`.
class TrucoGameModel {
  const TrucoGameModel._();

  static TrucoGame fromFirestore(
    String id,
    Map<String, dynamic> json,
    List<TrucoHand> hands,
  ) {
    return TrucoGame(
      id: id,
      mode: TrucoMode.fromPlayersPerTeam(json['mode'] as int? ?? 1),
      targetScore: json['targetScore'] as int? ?? 30,
      teamA: _teamFrom(json['teamA'], TrucoTeam.defaultNameA),
      teamB: _teamFrom(json['teamB'], TrucoTeam.defaultNameB),
      scoreA: json['scoreA'] as int? ?? 0,
      scoreB: json['scoreB'] as int? ?? 0,
      status: TrucoGameStatus.fromKey(json['status']),
      winner: TrucoTeamSide.fromKey(json['winnerTeam']),
      date: json['date'] as int? ?? 0,
      currentHand: json['currentHand'] as int? ?? 1,
      hands: hands,
    );
  }

  static Map<String, dynamic> toJson(TrucoGame game) {
    return {
      'mode': game.mode.playersPerTeam,
      'targetScore': game.targetScore,
      'teamA': _teamToJson(game.teamA),
      'teamB': _teamToJson(game.teamB),
      // Flat list so games can be queried by player.
      'playerIds': game.allPlayerIds,
      'scoreA': game.scoreA,
      'scoreB': game.scoreB,
      'status': game.status.name,
      'winnerTeam': game.winner?.key,
      'date': game.date,
      'currentHand': game.currentHand,
    };
  }

  static TrucoTeam _teamFrom(Object? raw, String fallbackName) {
    if (raw is! Map) return TrucoTeam(name: fallbackName);
    return TrucoTeam(
      name: raw['name'] as String? ?? fallbackName,
      playerIds: List<String>.from(raw['playerIds'] as List? ?? const []),
    );
  }

  static Map<String, dynamic> _teamToJson(TrucoTeam team) {
    return {'name': team.name, 'playerIds': team.playerIds};
  }
}
