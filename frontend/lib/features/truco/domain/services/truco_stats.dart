import 'package:equatable/equatable.dart';

import '../entities/truco_game.dart';
import '../entities/truco_participant.dart';
import '../entities/truco_team.dart';

/// One row of the ranking, from the player's persisted totals.
class TrucoRankingEntry extends Equatable {
  final String playerId;
  final String name;
  final int played;
  final int won;

  const TrucoRankingEntry({
    required this.playerId,
    required this.name,
    required this.played,
    required this.won,
  });

  double get winRate => played > 0 ? won / played : 0;

  String get winRateLabel => '${(winRate * 100).toStringAsFixed(1)}%';

  @override
  List<Object?> get props => [playerId, name, played, won];
}

/// Ranking like La Loba and Dardos: most wins first, then best win rate,
/// then name. A team win counts for every member of the team.
List<TrucoRankingEntry> buildTrucoRanking(List<TrucoParticipant> players) {
  final entries = players
      .map((p) => TrucoRankingEntry(
            playerId: p.id,
            name: p.name,
            played: p.totalGamesPlayed,
            won: p.totalGamesWon,
          ))
      .toList()
    ..sort((a, b) {
      final wins = b.won.compareTo(a.won);
      if (wins != 0) return wins;
      final rate = b.winRate.compareTo(a.winRate);
      if (rate != 0) return rate;
      return a.name.compareTo(b.name);
    });
  return entries;
}

enum TrucoPlayerResult { won, lost, inProgress }

/// One game from a player's point of view.
class TrucoPlayerGameEntry extends Equatable {
  final TrucoGame game;
  final TrucoTeamSide side;
  final List<String> partnerIds;
  final List<String> opponentIds;
  final TrucoPlayerResult result;

  const TrucoPlayerGameEntry({
    required this.game,
    required this.side,
    required this.partnerIds,
    required this.opponentIds,
    required this.result,
  });

  @override
  List<Object?> get props => [game, side, partnerIds, opponentIds, result];
}

class TrucoPlayerHistory extends Equatable {
  /// Newest first.
  final List<TrucoPlayerGameEntry> entries;

  const TrucoPlayerHistory(this.entries);

  int get won => entries.where((e) => e.result == TrucoPlayerResult.won).length;

  int get lost =>
      entries.where((e) => e.result == TrucoPlayerResult.lost).length;

  /// Finished games only.
  int get played => won + lost;

  @override
  List<Object?> get props => [entries];
}

/// Every game [playerId] sat in, with their team, partners, opponents and
/// result.
TrucoPlayerHistory trucoPlayerHistory(String playerId, List<TrucoGame> games) {
  final entries = <TrucoPlayerGameEntry>[];
  for (final game in games) {
    final side = game.sideOf(playerId);
    if (side == null) continue;

    final TrucoPlayerResult result;
    if (!game.isFinished || game.winner == null) {
      result = TrucoPlayerResult.inProgress;
    } else {
      result =
          game.winner == side ? TrucoPlayerResult.won : TrucoPlayerResult.lost;
    }

    entries.add(TrucoPlayerGameEntry(
      game: game,
      side: side,
      partnerIds:
          game.teamOf(side).playerIds.where((id) => id != playerId).toList(),
      opponentIds: game.teamOf(side.other).playerIds,
      result: result,
    ));
  }
  entries.sort((a, b) => b.game.date.compareTo(a.game.date));
  return TrucoPlayerHistory(entries);
}
