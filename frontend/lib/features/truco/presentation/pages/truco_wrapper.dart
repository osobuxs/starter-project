import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_players_tab.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/truco_route_names.dart';

/// Truco section with its bottom navigation, like La Loba and Dardos.
class TrucoWrapper extends StatefulWidget {
  const TrucoWrapper({super.key});

  @override
  State<TrucoWrapper> createState() => _TrucoWrapperState();
}

class _TrucoWrapperState extends State<TrucoWrapper> {
  static const _titles = ['Truco · Iniciar', 'Truco · Jugadores'];

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppSectionScaffold(
      title: _titles[_tabIndex],
      currentRouteName: TrucoRouteNames.truco,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: const [
                TrucoIniciarTab(),
                TrucoPlayersTab(),
              ],
            ),
          ),
          BottomNavigationBar(
            currentIndex: _tabIndex,
            onTap: (index) => setState(() => _tabIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.play_arrow),
                label: 'Iniciar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Jugadores',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
