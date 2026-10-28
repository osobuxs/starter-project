import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_stats.dart';

TrucoGame _game(
  String id, {
  required int date,
  List<String> teamA = const ['ana', 'alma'],
  List<String> teamB = const ['beto', 'bruno'],
  TrucoTeamSide? winner,
}) {
  return TrucoGame(
    id: id,
    mode: TrucoMode.fromPlayersPerTeam(teamA.length),
    targetScore: 30,
    teamA: TrucoTeam(name: 'Nosotros', playerIds: teamA),
    teamB: TrucoTeam(name: 'Ellos', playerIds: teamB),
    date: date,
    status: winner == null ? TrucoGameStatus.playing : TrucoGameStatus.finished,
    winner: winner,
  );
}

void main() {
  group('buildTrucoRanking', () {
    test('sorts by wins, then win rate, then name', () {
      final ranking = buildTrucoRanking(const [
        TrucoParticipant(
            id: 'c', name: 'Caro', totalGamesPlayed: 4, totalGamesWon: 2),
        TrucoParticipant(
            id: 'a', name: 'Ana', totalGamesPlayed: 10, totalGamesWon: 5),
        TrucoParticipant(
            id: 'b', name: 'Beto', totalGamesPlayed: 2, totalGamesWon: 2),
        TrucoParticipant(
            id: 'd', name: 'Dani', totalGamesPlayed: 4, totalGamesWon: 2),
      ]);

      expect(ranking.map((e) => e.playerId), ['a', 'b', 'c', 'd']);
      expect(ranking.first.winRate, 0.5);
      expect(ranking.first.winRateLabel, '50.0%');
    });

    test('players without games have a zero win rate', () {
      final ranking = buildTrucoRanking(
        const [TrucoParticipant(id: 'z', name: 'Zoe')],
      );

      expect(ranking.single.winRate, 0);
      expect(ranking.single.winRateLabel, '0.0%');
    });
  });

  group('trucoPlayerHistory', () {
    final games = [
      _game('old', date: 1, winner: TrucoTeamSide.a),
      _game('lost', date: 2, winner: TrucoTeamSide.b),
      _game('live', date: 3),
      _game(
        'other',
        date: 4,
        teamA: const ['x'],
        teamB: const ['y'],
        winner: TrucoTeamSide.a,
      ),
    ];

    test('lists the player games newest first with partners and opponents', () {
      final history = trucoPlayerHistory('alma', games);

      expect(history.entries.map((e) => e.game.id), ['live', 'lost', 'old']);
      final old = history.entries.last;
      expect(old.side, TrucoTeamSide.a);
      expect(old.partnerIds, ['ana']);
      expect(old.opponentIds, ['beto', 'bruno']);
      expect(old.result, TrucoPlayerResult.won);
      expect(history.entries[1].result, TrucoPlayerResult.lost);
      expect(history.entries.first.result, TrucoPlayerResult.inProgress);
    });

    test('totals count only finished games', () {
      final history = trucoPlayerHistory('beto', games);

      expect(history.played, 2);
      expect(history.won, 1);
      expect(history.lost, 1);
    });
  });
}
