import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

class GameHistoryTile extends StatelessWidget {
  final GameEntity game;
  final VoidCallback onTap;

  const GameHistoryTile({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(game.createdAt);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final isFinished = game.status == 'finished';
    final playerNames = game.players.map((p) => p.name).join(', ');

    return ListTile(
      leading: Icon(
        isFinished ? Icons.check_circle : Icons.play_circle_filled,
        color: isFinished ? Colors.green : Colors.orange,
      ),
      title: Text(game.name),
      subtitle: Text(
        '$formattedDate\n$playerNames',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: Text(
        isFinished ? 'Terminado' : 'En juego',
        style: TextStyle(
          color: isFinished ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
