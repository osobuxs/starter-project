import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/game_history_tile.dart';

class LaLobaHomePage extends StatelessWidget {
  const LaLobaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionScaffold(
      title: 'La Loba',
      currentRouteName: AppRouteNames.laLoba,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouteNames.laLobaCreate);
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state.status == GameBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay partidas todavía',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tocá + para crear un nuevo juego',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: state.games.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final game = state.games[index];
              return GameHistoryTile(
                game: game,
                onTap: () {
                  if (game.status == 'finished') {
                    Navigator.of(context).pushNamed(
                      AppRouteNames.laLobaFinished,
                      arguments: game.id,
                    );
                  } else {
                    Navigator.of(context).pushNamed(
                      AppRouteNames.laLobaPlay,
                      arguments: game.id,
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
