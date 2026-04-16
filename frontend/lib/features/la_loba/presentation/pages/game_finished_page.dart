import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

class GameFinishedPage extends StatelessWidget {
  final int gameId;

  const GameFinishedPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Juego terminado',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state.status == GameBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = state.game;
          if (game == null) {
            return const Center(child: Text('Error al cargar el juego'));
          }

          // Sort by totalScore ascending (winner = lowest)
          final sortedPlayers = List.of(game.players)
            ..sort((a, b) => a.totalScore.compareTo(b.totalScore));

          return Column(
            children: [
              // Winner banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.amber.shade100,
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                    const SizedBox(height: 8),
                    Text(
                      'Ganador: ${sortedPlayers.first.name}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${sortedPlayers.first.totalScore} puntos',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),

              // Ranking
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ranking final',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index == 0
                            ? Colors.amber
                            : (player.isEliminated
                                ? Colors.red.shade100
                                : Colors.grey.shade200),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      title: Text(player.name),
                      subtitle: Text(
                        player.isEliminated ? 'Eliminado' : 'Activo',
                        style: TextStyle(
                          color: player.isEliminated
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      trailing: Text(
                        '${player.totalScore} pts',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRouteNames.laLoba,
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text('Volver'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                            AppRouteNames.laLobaCreate,
                          );
                        },
                        child: const Text('Nuevo juego'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
