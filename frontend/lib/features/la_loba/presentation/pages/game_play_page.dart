import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

class GamePlayPage extends StatelessWidget {
  final String gameId;

  const GamePlayPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state.status == GameBlocStatus.gameFinished) {
          Navigator.of(context).pushReplacementNamed(
            AppRouteNames.laLobaFinished,
            arguments: gameId,
          );
        }

        if (state.status == GameBlocStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final game = state.game;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${game?.name ?? "La Loba"} — Mano ${game?.currentHand ?? 0}',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          body: state.status == GameBlocStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : game == null
                  ? const Center(child: Text('No hay juego cargado'))
                  : Column(
                      children: [
                        // Participant count
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Participantes: ${game.participantIds.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Score input cards for participants
                        Expanded(
                          child: ListView.builder(
                            itemCount: game.participantIds.length,
                            itemBuilder: (context, index) {
                              final participantId = game.participantIds[index];
                              final currentScore =
                                  state.currentHandScores[participantId] ?? 0;

                              return ListTile(
                                title: Text('Participante $participantId'),
                                trailing: SizedBox(
                                  width: 100,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: '$currentScore pts',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final score = int.tryParse(value) ?? 0;
                                      context.read<GameBloc>().add(
                                        RecordScoreEvent(
                                          participantId: participantId,
                                          points: score,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Finish hand button
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<GameBloc>().add(
                                  FinishPartidaEvent(gameId),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Finalizar Mano',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
