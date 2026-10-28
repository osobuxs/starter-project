import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_state.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_game_tile.dart';

/// Finished games, newest first. Opening one shows its board read-only.
class TrucoHistoryTab extends StatelessWidget {
  const TrucoHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final names = context.watch<TrucoParticipantBloc>().state.namesById;

    return BlocBuilder<TrucoMultiGameBloc, TrucoMultiGameState>(
      builder: (context, state) {
        final games = state.finishedGames;
        if (state.status == TrucoMultiGameStatus.loading && games.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (games.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Todavía no hay partidas terminadas',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context
              .read<TrucoMultiGameBloc>()
              .add(const LoadTrucoGamesEvent()),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: games.length,
            itemBuilder: (context, index) => TrucoGameTile(
              game: games[index],
              namesById: names,
              onTap: () => openTrucoGame(context, games[index].id),
            ),
          ),
        );
      },
    );
  }
}
