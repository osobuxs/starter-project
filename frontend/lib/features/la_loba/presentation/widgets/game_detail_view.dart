import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

class GameDetailView extends StatelessWidget {
  final GameEntity game;
  final Map<String, String> participantNames; // participantId -> name

  const GameDetailView({
    super.key,
    required this.game,
    required this.participantNames,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(game.date));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Participantes',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${game.participantIds.length}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Winner section
            if (game.winnerId != null)
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber[700],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ganador',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              participantNames[game.winnerId] ?? 'Desconocido',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, color: Colors.grey),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Ganador no registrado',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Scores section
            const Text(
              'Puntajes Finales',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    if (game.participantStates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Sin puntajes registrados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...game.participantStates.entries.map((entry) {
                        final participantId = entry.key;
                        final score = entry.value['totalScore'] ?? 0;
                        final name = participantNames[participantId] ?? 'Desconocido';
                        final isWinner = participantId == game.winnerId;

                        return ListTile(
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                              color: isWinner ? Colors.amber[700] : Colors.black,
                            ),
                          ),
                          trailing: Text(
                            '$score pts',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isWinner ? Colors.amber[700] : Colors.black,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
