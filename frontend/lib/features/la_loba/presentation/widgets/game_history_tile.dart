import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

class GameHistoryTile extends StatelessWidget {
  final GameEntity game;
  final VoidCallback onTap;
  final bool showWinner;

  const GameHistoryTile({
    super.key,
    required this.game,
    required this.onTap,
    this.showWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = game.date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(game.date))
        : 'Sin fecha';

    final isFinished = game.status == 'finished';
    final isPaused = game.status == 'paused';
    final isPlaying = game.status == 'playing';

    Color statusColor = Colors.grey;
    String statusLabel = 'Desconocido';

    if (isFinished) {
      statusColor = Colors.green;
      statusLabel = 'Finalizada';
    } else if (isPaused) {
      statusColor = Colors.orange;
      statusLabel = 'Pausada';
    } else if (isPlaying) {
      statusColor = Colors.blue;
      statusLabel = 'En juego';
    }

    return ListTile(
      leading: Icon(
        isFinished ? Icons.check_circle : (isPaused ? Icons.pause_circle : Icons.play_circle_filled),
        color: statusColor,
      ),
      title: Text(game.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Participantes: ${game.participantIds?.length ?? 0}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: showWinner && isFinished && game.winnerId != null
          ? Icon(
              Icons.emoji_events,
              color: Colors.amber[700],
            )
          : Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
      onTap: onTap,
    );
  }
}
