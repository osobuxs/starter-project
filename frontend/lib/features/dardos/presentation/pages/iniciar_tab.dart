import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';

class IniciarTab extends StatefulWidget {
  const IniciarTab({Key? key}) : super(key: key);

  @override
  State<IniciarTab> createState() => _IniciarTabState();
}

class _IniciarTabState extends State<IniciarTab> {
  @override
  void initState() {
    super.initState();
    context.read<DardosMultiGameBloc>().add(LoadGamesEvent());
    context.read<DardosParticipantBloc>().add(CheckAdminStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DardosMultiGameBloc, DardosMultiGameState>(
      builder: (context, state) {
        if (state.status == DardosMultiGameStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allGames = List.from(state.games)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (allGames.isEmpty) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Iniciar',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_score,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay partidas activas. ¡Crea una!',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tocá + para crear un nuevo juego',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(AppRouteNames.dardosCreate);
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
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouteNames.dardosCreate);
              },
              child: const Icon(Icons.add),
            ),
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
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<DardosMultiGameBloc>()
                            .add(LoadGamesEvent());
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: allGames.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                        final game = allGames[index];
                        return ListTile(
                          title: Text(game.name as String),
                          subtitle: Text(
                            '${(game.mode as String).toUpperCase()} · '
                            '${(game.playerIds as List).length} jugadores · '
                            '${game.status}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (game.status == 'finished') {
                              Navigator.of(context).pushNamed(
                                AppRouteNames.dardosFinished,
                                arguments: game.id,
                              );
                              return;
                            }
                            Navigator.of(context).pushNamed(
                              AppRouteNames.dardosPlay,
                              arguments: game.id,
                            );
                          },
                        );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouteNames.dardosCreate);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
