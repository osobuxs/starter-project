import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/utils/participant_display.dart';

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
            return BlocBuilder<ParticipantBloc, ParticipantState>(
              builder: (context, participantState) {
                // Filter games based on criteria
                var filteredGames =
                    List<GameEntity>.from(gameState.finishedGames);

                // Apply date range filter
                if (_dateStart != null) {
                  filteredGames = filteredGames.where((g) {
                    final gameDate =
                        DateTime.fromMillisecondsSinceEpoch(g.date);
                    return gameDate.isAfter(_dateStart!);
                  }).toList();
                }
                if (_dateEnd != null) {
                  filteredGames = filteredGames.where((g) {
                    final gameDate =
                        DateTime.fromMillisecondsSinceEpoch(g.date);
                    return gameDate.isBefore(_dateEnd!);
                  }).toList();
                }

                // Apply participant filter
                if (navState.filters.containsKey('participantId')) {
                  final participantId = navState.filters['participantId'];
                  filteredGames = filteredGames.where((g) {
                    return g.participantIds.contains(participantId);
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
                  final dateA = DateTime.fromMillisecondsSinceEpoch(a.date);
                  final dateB = DateTime.fromMillisecondsSinceEpoch(b.date);
                  return dateB.compareTo(dateA);
                });

                final participantNames = {
                  for (final p in participantState.participants) p.id: p.name,
                };

                final ranking = <_RankingStat>[];
                final byId = <String, _RankingStat>{};

                final hasFilters = _dateStart != null ||
                    _dateEnd != null ||
                    navState.filters.containsKey('participantId') ||
                    navState.filters.containsKey('winnerId');

                if (!hasFilters) {
                  for (final participant in participantState.participants) {
                    byId[participant.id] = _RankingStat(
                      name: participant.name,
                      gamesPlayed: participant.totalGamesPlayed,
                      gamesWon: participant.totalGamesWon,
                    );
                  }
                } else {
                  for (final game in filteredGames) {
                    for (final participantId in game.participantIds) {
                      byId.putIfAbsent(
                        participantId,
                        () => _RankingStat(
                          name: resolveParticipantName(
                            participantId,
                            participantNames,
                          ),
                        ),
                      );
                      byId[participantId]!.gamesPlayed++;
                    }

                    final winnerId = game.winnerId;
                    if (winnerId != null && byId.containsKey(winnerId)) {
                      byId[winnerId]!.gamesWon++;
                    }
                  }
                }

                ranking
                  ..addAll(byId.values)
                  ..sort((a, b) {
                    final winsCmp = b.gamesWon.compareTo(a.gamesWon);
                    if (winsCmp != 0) return winsCmp;

                    final rateCmp = b.winRate.compareTo(a.winRate);
                    if (rateCmp != 0) return rateCmp;

                    return a.name.compareTo(b.name);
                  });

                return Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ranking',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _dateStart ?? DateTime.now(),
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
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                        ),
                                        child: Text(
                                          _dateStart != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_dateStart!)
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
                                          initialDate:
                                              _dateEnd ?? DateTime.now(),
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
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                        ),
                                        child: Text(
                                          _dateEnd != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_dateEnd!)
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
                          const SizedBox(height: 8),
                          Expanded(
                            child: ranking.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.emoji_events,
                                            size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'No hay datos para ranking',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: ranking.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = ranking[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.indigo.shade50,
                                          child: Text(
                                            '#${index + 1}',
                                            style: TextStyle(
                                              color: Colors.indigo.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Jugadas: ${item.gamesPlayed} · Ganadas: ${item.gamesWon} · Winrate: ${item.winRateLabel}',
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RankingStat {
  final String name;
  int gamesPlayed;
  int gamesWon;

  _RankingStat({
    required this.name,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0;

  String get winRateLabel => '${(winRate * 100).toStringAsFixed(1)}%';
}
