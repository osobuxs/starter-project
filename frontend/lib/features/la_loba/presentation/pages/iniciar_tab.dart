import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/game_history_tile.dart';

class IniciarTab extends StatelessWidget {
  const IniciarTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultiGameBloc, MultiGameState>(
      builder: (context, state) {
        if (state.status == MultiGameBlocStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasGames =
            state.activeGame != null ||
            state.pausedGames.isNotEmpty ||
            state.finishedGames.isNotEmpty;

        if (!hasGames) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.casino, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay partidas todavía',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tocá + para crear un nuevo juego',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouteNames.laLobaCreate);
                    },
                    child: const Text('Crear Partida'),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouteNames.laLobaCreate);
              },
              child: const Icon(Icons.add),
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Active game (if any)
              if (state.activeGame != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Partida Activa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.activeGame!.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouteNames.laLobaPlay,
                                      arguments: state.activeGame!.id,
                                    );
                                  },
                                  child: const Text('Continuar'),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    context.read<MultiGameBloc>().add(
                                      PauseGameEvent(state.activeGame!.id),
                                    );
                                  },
                                  child: const Text('Pausar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Paused games section
              if (state.pausedGames.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Partidas Pausadas (${state.pausedGames.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = state.pausedGames[index];
                      return GameHistoryTile(
                        game: game,
                        onTap: () {
                          context.read<MultiGameBloc>().add(
                            ResumeGameEvent(game.id),
                          );
                          Navigator.of(context).pushNamed(
                            AppRouteNames.laLobaPlay,
                            arguments: game.id,
                          );
                        },
                      );
                    },
                    childCount: state.pausedGames.length,
                  ),
                ),
              ],
              // Finished games section
              if (state.finishedGames.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Partidas Finalizadas (${state.finishedGames.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = state.finishedGames[index];
                      return GameHistoryTile(
                        game: game,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRouteNames.laLobaFinished,
                            arguments: game.id,
                          );
                        },
                      );
                    },
                    childCount: state.finishedGames.length,
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouteNames.laLobaCreate);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
