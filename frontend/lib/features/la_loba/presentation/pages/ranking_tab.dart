import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/game_history_tile.dart';

class RankingTab extends StatefulWidget {
  const RankingTab({Key? key}) : super(key: key);

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  DateTime? _dateStart;
  DateTime? _dateEnd;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavBloc, BottomNavState>(
      builder: (context, navState) {
        return BlocBuilder<MultiGameBloc, MultiGameState>(
          builder: (context, gameState) {
            // Filter games based on criteria
            var filteredGames = List<dynamic>.from(gameState.finishedGames);

            // Apply date range filter
            if (_dateStart != null) {
              filteredGames = filteredGames.where((g) {
                final gameDate = g.date ?? DateTime.now();
                return gameDate.isAfter(_dateStart!);
              }).toList();
            }
            if (_dateEnd != null) {
              filteredGames = filteredGames.where((g) {
                final gameDate = g.date ?? DateTime.now();
                return gameDate.isBefore(_dateEnd!);
              }).toList();
            }

            // Apply participant filter
            if (navState.filters.containsKey('participantId')) {
              final participantId = navState.filters['participantId'];
              filteredGames = filteredGames.where((g) {
                return g.participantIds?.contains(participantId) ?? false;
              }).toList();
            }

            // Apply winner filter
            if (navState.filters.containsKey('winnerId')) {
              final winnerId = navState.filters['winnerId'];
              filteredGames = filteredGames.where((g) {
                return g.winnerId == winnerId;
              }).toList();
            }

            // Sort by date descending
            filteredGames.sort((a, b) {
              final dateA = a.date ?? DateTime.now();
              final dateB = b.date ?? DateTime.now();
              return dateB.compareTo(dateA);
            });

            return Scaffold(
              body: Column(
                children: [
                  // Filter controls
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _dateStart ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _dateStart = date);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Desde',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    _dateStart != null
                                        ? DateFormat('dd/MM/yyyy').format(_dateStart!)
                                        : 'Sin filtro',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _dateEnd ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _dateEnd = date);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Hasta',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    _dateEnd != null
                                        ? DateFormat('dd/MM/yyyy').format(_dateEnd!)
                                        : 'Sin filtro',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_dateStart != null || _dateEnd != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _dateStart = null;
                                    _dateEnd = null;
                                  });
                                },
                                child: const Text('Limpiar fechas'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Games list
                  Expanded(
                    child: filteredGames.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.emoji_events,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No hay partidas finalizadas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredGames.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final game = filteredGames[index];
                              return GameHistoryTile(
                                game: game,
                                showWinner: true,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRouteNames.laLobaFinished,
                                    arguments: game.id,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
