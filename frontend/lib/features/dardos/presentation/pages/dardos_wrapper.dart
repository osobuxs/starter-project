import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/pages/iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/pages/jugadores_tab.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/pages/ranking_tab.dart';

class DardosWrapper extends StatelessWidget {
  const DardosWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DardosBottomNavBloc, DardosBottomNavState>(
      builder: (context, state) {
        final titles = [
          'Dardos · Iniciar',
          'Dardos · Jugadores',
          'Dardos · Ranking',
        ];

        return AppSectionScaffold(
          title: titles[state.currentTabIndex],
          currentRouteName: AppRouteNames.dardos,
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
                    JugadoresTab(),
                    RankingTab(),
                  ],
                ),
              ),
              BottomNavigationBar(
                currentIndex: state.currentTabIndex,
                onTap: (index) {
                  context.read<DardosBottomNavBloc>().add(ChangeTabEvent(index));
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.play_arrow),
                    label: 'Iniciar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Jugadores',
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
