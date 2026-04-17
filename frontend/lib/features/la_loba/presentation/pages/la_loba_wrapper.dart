import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/ranking_tab.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/usuarios_tab.dart';

class LaLobaWrapper extends StatelessWidget {
  const LaLobaWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavBloc, BottomNavState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: state.currentTabIndex,
            children: const [
              IniciarTab(),
              UsuariosTab(),
              RankingTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.currentTabIndex,
            onTap: (index) {
              context.read<BottomNavBloc>().add(ChangeTabEvent(index));
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.play_arrow),
                label: 'Iniciar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Usuarios',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard),
                label: 'Ranking',
              ),
            ],
          ),
        );
      },
    );
  }
}
