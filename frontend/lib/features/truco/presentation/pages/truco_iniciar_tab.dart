import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_state.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/truco_route_names.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_game_tile.dart';

/// Games in progress, plus "new game" for the admin.
class TrucoIniciarTab extends StatelessWidget {
  const TrucoIniciarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final participantState = context.watch<TrucoParticipantBloc>().state;

    return BlocBuilder<TrucoMultiGameBloc, TrucoMultiGameState>(
      builder: (context, state) {
        final games = state.playingGames;
        Widget body;
        if (state.status == TrucoMultiGameStatus.loading && games.isEmpty) {
          body = const Center(child: CircularProgressIndicator());
        } else if (games.isEmpty) {
          body = const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.style, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay partidas en juego',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        } else {
          body = RefreshIndicator(
            onRefresh: () async => context
                .read<TrucoMultiGameBloc>()
                .add(const LoadTrucoGamesEvent()),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: games.length,
              itemBuilder: (context, index) => TrucoGameTile(
                game: games[index],
                namesById: participantState.namesById,
                onTap: () => openTrucoGame(context, games[index].id),
              ),
            ),
          );
        }

        return Scaffold(
          body: body,
          floatingActionButton: participantState.isAdmin
              ? FloatingActionButton.extended(
                  heroTag: 'truco-new-game',
                  onPressed: () async {
                    await Navigator.of(context)
                        .pushNamed(TrucoRouteNames.create);
                    if (context.mounted) {
                      context
                          .read<TrucoMultiGameBloc>()
                          .add(const LoadTrucoGamesEvent());
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva partida'),
                )
              : null,
        );
      },
    );
  }
}

/// Opens a game's board and refreshes the lists when coming back.
Future<void> openTrucoGame(BuildContext context, String gameId) async {
  await Navigator.of(context)
      .pushNamed(TrucoRouteNames.play, arguments: gameId);
  if (context.mounted) {
    context.read<TrucoMultiGameBloc>().add(const LoadTrucoGamesEvent());
  }
}
