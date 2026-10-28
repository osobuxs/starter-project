import 'package:equatable/equatable.dart';

import '../services/truco_score_rules.dart';
import 'truco_hand.dart';
import 'truco_team.dart';

/// Table size: how many players each team has.
enum TrucoMode {
  oneVsOne(1),
  twoVsTwo(2),
  threeVsThree(3);

  final int playersPerTeam;

  const TrucoMode(this.playersPerTeam);

  String get label => '$playersPerTeam vs $playersPerTeam';

  static TrucoMode fromPlayersPerTeam(int value) {
    return TrucoMode.values.firstWhere(
      (mode) => mode.playersPerTeam == value,
      orElse: () => TrucoMode.oneVsOne,
    );
  }
}

enum TrucoGameStatus {
  playing,
  finished;

  static TrucoGameStatus fromKey(Object? value) =>
      value == finished.name ? finished : playing;
}

/// Valid targets: 18 (9 malas + 9 buenas) or 30 (15 + 15).
const trucoTargetScores = [18, 30];

class TrucoGame extends Equatable {
  final String id;
  final TrucoMode mode;
  final int targetScore;
  final TrucoTeam teamA;
  final TrucoTeam teamB;
  final int scoreA;
  final int scoreB;
  final TrucoGameStatus status;
  final TrucoTeamSide? winner;
  final int date;

  /// Number of the hand being played (closed hands + 1).
  final int currentHand;
  final List<TrucoHand> hands;

  const TrucoGame({
    required this.id,
    required this.mode,
    required this.targetScore,
    required this.teamA,
    required this.teamB,
    required this.date,
    this.scoreA = 0,
    this.scoreB = 0,
    this.status = TrucoGameStatus.playing,
    this.winner,
    this.currentHand = 1,
    this.hands = const [],
  });

  bool get isFinished => status == TrucoGameStatus.finished;

  TrucoTeam teamOf(TrucoTeamSide side) =>
      side == TrucoTeamSide.a ? teamA : teamB;

  int scoreOf(TrucoTeamSide side) => side == TrucoTeamSide.a ? scoreA : scoreB;

  List<String> get allPlayerIds => [...teamA.playerIds, ...teamB.playerIds];

  /// Players around the table: A1, B1, A2, B2, ...
  List<String> get seatingOrder =>
      trucoSeatingOrder(teamA.playerIds, teamB.playerIds);

  /// Side the player belongs to, or null if they are not in this game.
  TrucoTeamSide? sideOf(String playerId) {
    if (teamA.playerIds.contains(playerId)) return TrucoTeamSide.a;
    if (teamB.playerIds.contains(playerId)) return TrucoTeamSide.b;
    return null;
  }

  TrucoGame copyWith({
    TrucoMode? mode,
    int? targetScore,
    TrucoTeam? teamA,
    TrucoTeam? teamB,
    int? scoreA,
    int? scoreB,
    TrucoGameStatus? status,
    TrucoTeamSide? winner,
    bool clearWinner = false,
    int? date,
    int? currentHand,
    List<TrucoHand>? hands,
  }) {
    return TrucoGame(
      id: id,
      mode: mode ?? this.mode,
      targetScore: targetScore ?? this.targetScore,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      status: status ?? this.status,
      winner: clearWinner ? null : (winner ?? this.winner),
      date: date ?? this.date,
      currentHand: currentHand ?? this.currentHand,
      hands: hands ?? this.hands,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mode,
        targetScore,
        teamA,
        teamB,
        scoreA,
        scoreB,
        status,
        winner,
        date,
        currentHand,
        hands,
      ];
}
