import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/game_history_tile.dart';

class IniciarTab extends StatelessWidget {
  const IniciarTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticipantBloc, ParticipantState>(
      builder: (context, participantState) {
        final canCreateGame = participantState.isAdmin;

        return BlocBuilder<MultiGameBloc, MultiGameState>(
          builder: (context, state) {
            if (state.status == MultiGameBlocStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allGames = [
              ...state.playingGames,
              ...state.pausedGames,
              ...state.finishedGames,
            ]..sort((a, b) => b.date.compareTo(a.date));

            final hasGames = allGames.isNotEmpty;

            if (!hasGames) {
              return Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.casino,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay partidas todavía',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tocá + para crear un nuevo juego',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                if (canCreateGame)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                          AppRouteNames.laLobaCreate);
                                    },
                                    child: const Text('Crear Partida'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                floatingActionButton: canCreateGame
                    ? FloatingActionButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(AppRouteNames.laLobaCreate);
                        },
                        child: const Icon(Icons.add),
                      )
                    : null,
              );
            }

            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: allGames.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final game = allGames[index];
                            return GameHistoryTile(
                              game: game,
                              showWinner: true,
                              onTap: () {
                                if (game.status == 'finished') {
                                  Navigator.of(context).pushNamed(
                                    AppRouteNames.laLobaFinished,
                                    arguments: game.id,
                                  );
                                  return;
                                }

                                if (game.status == 'paused') {
                                  context
                                      .read<MultiGameBloc>()
                                      .add(ResumeGameEvent(game.id));
                                }

                                Navigator.of(context).pushNamed(
                                  AppRouteNames.laLobaPlay,
                                  arguments: game.id,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: canCreateGame
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRouteNames.laLobaCreate);
                      },
                      child: const Icon(Icons.add),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
