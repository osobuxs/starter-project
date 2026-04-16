import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/player_score_card.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/retry_dialog.dart';

class GamePlayPage extends StatelessWidget {
  final int gameId;

  const GamePlayPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state.status == GameBlocStatus.retryOffered &&
            state.retryCandidates.isNotEmpty) {
          final candidate = state.retryCandidates.first;
          RetryDialog.show(
            context,
            player: candidate,
            onAccept: () {
              Navigator.of(context).pop();
              context.read<GameBloc>().add(
                DoRetryEvent(gameId: gameId, playerId: candidate.id!),
              );
            },
            onReject: () {
              Navigator.of(context).pop();
              context.read<GameBloc>().add(
                RejectRetryEvent(gameId: gameId, playerId: candidate.id!),
              );
            },
          );
        }

        if (state.status == GameBlocStatus.gameOver) {
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
        final activePlayers = game?.activePlayers ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${game?.name ?? "La Loba"} — Partida ${state.currentPartidaNumber}',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          body: state.status == GameBlocStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Active vs eliminated indicator
                    if (game != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Activos: ${activePlayers.length}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Eliminados: ${game.players.length - activePlayers.length}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Player score cards
                    Expanded(
                      child: ListView.builder(
                        itemCount: activePlayers.length,
                        itemBuilder: (context, index) {
                          final player = activePlayers[index];
                          final currentScore =
                              state.currentPartidaScores[player.id] ?? 0;

                          return PlayerScoreCard(
                            player: player,
                            currentPartidaScore: currentScore,
                            onScoreChanged: (newScore) {
                              context.read<GameBloc>().add(
                                RecordScoreEvent(
                                  playerId: player.id!,
                                  points: newScore,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Finish partida button
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
                            'Finalizar partida',
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
