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
  final int? turnIndex;
  final String? liveMetricText;
  final List<DardosThrowEntity> currentTurnDarts;

  const PlayerDartCard({
    super.key,
    required this.name,
    required this.isCurrentTurn,
    required this.mode,
    this.remainingScore,
    this.cricketPoints,
    this.turnIndex,
    this.liveMetricText,
    this.currentTurnDarts = const [],
  });

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
    final bigScore =
        isCricket ? '${cricketPoints ?? 0}' : '${remainingScore ?? 0}';
    final bgColor =
        isCurrentTurn ? Colors.amber.shade100 : Colors.grey.shade100;
    final accentColor =
        isCurrentTurn ? Colors.deepOrange : Colors.blueGrey.shade700;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: isCurrentTurn ? Colors.deepOrange : Colors.grey.shade300,
          width: isCurrentTurn ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: Colors.deepOrange.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (liveMetricText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    liveMetricText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
                if (isCurrentTurn && currentTurnDarts.isEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Primer dardo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
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
                  isCurrentTurn
                      ? 'Turno actual: $_turnTotal'
                      : 'Total turno ant.: $_turnTotal',
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
                if (turnIndex != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    isCurrentTurn
                        ? 'Turno ${turnIndex! + 1}'
                        : 'Turno ant. ${turnIndex! + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
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
  const _DartChip({this.dart});

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
          child: Text('—', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
