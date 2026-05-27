import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

/// Compact horizontal scoreboard row for a player.
/// Left: name + remaining score (huge, dominant).
/// Right: turn total + the 3 darts of current turn as small chips.
class PlayerDartCard extends StatelessWidget {
  final String name;
  final bool isCurrentTurn;
  final String mode;
  final int? remainingScore;
  final int? cricketPoints;
  final List<DardosThrowEntity> currentTurnDarts;

  const PlayerDartCard({
    Key? key,
    required this.name,
    required this.isCurrentTurn,
    required this.mode,
    this.remainingScore,
    this.cricketPoints,
    this.currentTurnDarts = const [],
  }) : super(key: key);

  int get _turnTotal {
    var t = 0;
    for (final d in currentTurnDarts) {
      if (d.isBust) continue;
      t += d.points;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final isCricket = mode == 'cricket';
    final bigScore = isCricket
        ? '${cricketPoints ?? 0}'
        : '${remainingScore ?? 0}';
    final bgColor = isCurrentTurn
        ? Colors.amber.shade100
        : Colors.grey.shade100;
    final accentColor =
        isCurrentTurn ? Colors.deepOrange : Colors.blueGrey.shade700;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: isCurrentTurn ? Colors.deepOrange : Colors.grey.shade300,
          width: isCurrentTurn ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Name + Big score (left)
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bigScore,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right: turn total + 3 dart chips
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Turno: $_turnTotal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(3, (i) {
                    final dart = i < currentTurnDarts.length
                        ? currentTurnDarts[i]
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _DartChip(dart: dart),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DartChip extends StatelessWidget {
  final DardosThrowEntity? dart;
  const _DartChip({Key? key, this.dart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dart == null) {
      return Container(
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Text('—',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      );
    }
    final d = dart!;
    String label;
    Color bg;
    if (d.isBust) {
      label = 'BUST';
      bg = Colors.red.shade400;
    } else if (d.isMiss) {
      label = '0';
      bg = Colors.grey.shade600;
    } else if (d.multiplier == 2) {
      label = 'D${d.number}';
      bg = Colors.blue.shade600;
    } else if (d.multiplier == 3) {
      label = 'T${d.number}';
      bg = Colors.deepPurple;
    } else {
      label = '${d.number}';
      bg = Colors.green.shade700;
    }
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
