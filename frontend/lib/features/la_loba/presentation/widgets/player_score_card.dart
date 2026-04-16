import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';

class PlayerScoreCard extends StatelessWidget {
  final PlayerEntity player;
  final int currentPartidaScore;
  final ValueChanged<int> onScoreChanged;

  const PlayerScoreCard({
    super.key,
    required this.player,
    required this.currentPartidaScore,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total: ${player.totalScore}',
                    style: TextStyle(
                      fontSize: 14,
                      color: player.totalScore >= 80
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onScoreChanged(currentPartidaScore - 5),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                key: ValueKey('score_${player.id}'),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: currentPartidaScore.toString(),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    onScoreChanged(parsed);
                  }
                },
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onScoreChanged(currentPartidaScore + 5),
            ),
          ],
        ),
      ),
    );
  }
}
