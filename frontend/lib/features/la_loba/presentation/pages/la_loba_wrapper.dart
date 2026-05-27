import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/ranking_tab.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/pages/usuarios_tab.dart';

class LaLobaWrapper extends StatelessWidget {
  const LaLobaWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavBloc, BottomNavState>(
      builder: (context, state) {
        final titles = [
          'La Loba · Iniciar',
          'La Loba · Usuarios',
          'La Loba · Ranking'
        ];

        return AppSectionScaffold(
          title: titles[state.currentTabIndex],
          currentRouteName: AppRouteNames.laLoba,
          actions: const [],
          floatingActionButton: null,
          drawerVariant: AppSectionDrawerVariant.full,
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: state.currentTabIndex,
                  children: const [
                    IniciarTab(),
                    UsuariosTab(),
                    RankingTab(),
                  ],
                ),
              ),
              BottomNavigationBar(
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
            ],
          ),
        );
      },
    );
  }
}
