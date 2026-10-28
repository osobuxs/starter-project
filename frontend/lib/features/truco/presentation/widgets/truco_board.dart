import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_score_rules.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_matchstick_painter.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_seating_preview.dart';

/// The "anotador": one column per team with its name, members, total and
/// the total drawn as matchsticks split into malas and buenas.
class TrucoBoard extends StatelessWidget {
  final TrucoGame game;
  final Map<String, String> namesById;

  const TrucoBoard({super.key, required this.game, required this.namesById});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2D3B0)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _TeamColumn(
                    game: game, side: TrucoTeamSide.a, namesById: namesById)),
            const VerticalDivider(
                width: 16, thickness: 1.5, color: Color(0xFFBCA77A)),
            Expanded(
                child: _TeamColumn(
                    game: game, side: TrucoTeamSide.b, namesById: namesById)),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final TrucoGame game;
  final TrucoTeamSide side;
  final Map<String, String> namesById;

  const _TeamColumn({
    required this.game,
    required this.side,
    required this.namesById,
  });

  @override
  Widget build(BuildContext context) {
    final team = game.teamOf(side);
    final score = game.scoreOf(side);
    final color = side == TrucoTeamSide.a ? trucoTeamAColor : trucoTeamBColor;
    final isWinner = game.isFinished && game.winner == side;
    final members =
        team.playerIds.map((id) => namesById[id] ?? '…').join(' · ');
    final buenas = isTrucoBuenas(score, game.targetScore);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWinner)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.emoji_events,
                    color: Color(0xFFF9A825), size: 20),
              ),
            Flexible(
              child: Text(
                team.name,
                key: ValueKey('truco-team-name-${side.key}'),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          members,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          key: ValueKey('truco-total-${side.key}'),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
        ),
        Text(
          buenas ? 'en las buenas' : 'en las malas',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TrucoMatchstickTally(
          key: ValueKey('truco-tally-${side.key}'),
          points: score,
          targetScore: game.targetScore,
          seed: side.index + 1,
        ),
      ],
    );
  }
}

/// A team's total drawn as matchsticks: malas on top, a labelled divider,
/// buenas below.
class TrucoMatchstickTally extends StatelessWidget {
  final int points;
  final int targetScore;
  final int seed;

  const TrucoMatchstickTally({
    super.key,
    required this.points,
    required this.targetScore,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final layout =
        trucoMatchstickLayout(points: points, targetScore: targetScore);
    final half = trucoHalfOf(targetScore);
    final slots = (half / 5).ceil();

    return Semantics(
      label: '$points puntos',
      child: Column(
        children: [
          const _HalfLabel('MALAS'),
          _groups(layout.malas, slots, seed * 2, 'malas'),
          const _HalfDivider(),
          const _HalfLabel('BUENAS'),
          _groups(layout.buenas, slots, seed * 2 + 1, 'buenas'),
        ],
      ),
    );
  }

  Widget _groups(List<int> groups, int slots, int seed, String half) {
    return SizedBox(
      width: double.infinity,
      height: slots * TrucoMatchstickPainter.cellExtent,
      child: CustomPaint(
        key: ValueKey('truco-sticks-$half'),
        painter:
            TrucoMatchstickPainter(groups: groups, slots: slots, seed: seed),
      ),
    );
  }
}

class _HalfLabel extends StatelessWidget {
  final String text;

  const _HalfLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8D6E63),
      ),
    );
  }
}

class _HalfDivider extends StatelessWidget {
  const _HalfDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: const Color(0xFF8D6E63))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.local_fire_department,
                size: 14, color: Color(0xFFC62828)),
          ),
          Expanded(child: Container(height: 2, color: const Color(0xFF8D6E63))),
        ],
      ),
    );
  }
}
