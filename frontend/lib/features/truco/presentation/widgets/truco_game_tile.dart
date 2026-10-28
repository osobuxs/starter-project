import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_table_view.dart';

/// One game in a list: name, date, mode, target, both teams with members, score
/// and (when finished) the winner.
class TrucoGameTile extends StatelessWidget {
  final TrucoGame game;
  final Map<String, String> namesById;
  final VoidCallback? onTap;

  const TrucoGameTile({
    super.key,
    required this.game,
    required this.namesById,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final winner = game.winner;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatTrucoDate(game.date)} · ${game.mode.label} · '
                      'a ${game.targetScore}',
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                  if (game.isFinished && winner != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.emoji_events,
                          size: 16, color: Color(0xFFF9A825)),
                      label: Text('Ganó ${game.teamOf(winner).name}'),
                    )
                  else if (!game.isFinished)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('En juego'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (final side in TrucoTeamSide.values)
                _TeamLine(game: game, side: side, namesById: namesById),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final TrucoGame game;
  final TrucoTeamSide side;
  final Map<String, String> namesById;

  const _TeamLine({
    required this.game,
    required this.side,
    required this.namesById,
  });

  @override
  Widget build(BuildContext context) {
    final team = game.teamOf(side);
    final members = team.playerIds.map((id) => namesById[id] ?? '…').join(', ');
    final isWinner = game.isFinished && game.winner == side;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            color: trucoTeamColor(side),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: team.name,
                    style: TextStyle(
                      fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '  $members',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '${game.scoreOf(side)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// dd/mm/yyyy for a millisecond timestamp.
String formatTrucoDate(int millis) {
  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
