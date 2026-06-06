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

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar partida'),
        content: Text(
          '¿Eliminar "$name"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
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
        final isAdmin = context.watch<DardosParticipantBloc>().state.isAdmin;

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
                          final tile = ListTile(
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
                          // Admins can delete non-finished games by swiping.
                          // Finished games hold counted stats — reopen first.
                          final canDelete =
                              isAdmin && game.status != 'finished';
                          if (!canDelete) return tile;
                          return Dismissible(
                            key: ValueKey(game.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (_) =>
                                _confirmDelete(context, game.name as String),
                            onDismissed: (_) {
                              context.read<DardosMultiGameBloc>().add(
                                    DeleteGameEvent(
                                      gameId: game.id as String,
                                      isAdmin: true,
                                    ),
                                  );
                            },
                            child: tile,
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
