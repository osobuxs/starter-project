import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/game_history_tile.dart';

class ParticipantDetailPage extends StatefulWidget {
  final String participantId;

  const ParticipantDetailPage({
    Key? key,
    required this.participantId,
  }) : super(key: key);

  @override
  State<ParticipantDetailPage> createState() => _ParticipantDetailPageState();
}

class _ParticipantDetailPageState extends State<ParticipantDetailPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticipantBloc, ParticipantState>(
      builder: (context, participantState) {
        ParticipantEntity? participant;
        try {
          participant = participantState.participants
              .firstWhere((p) => p.id == widget.participantId);
        } catch (e) {
          participant = null;
        }

        if (participant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de Usuario')),
            body: const Center(child: Text('Usuario no encontrado')),
          );
        }

        return BlocBuilder<MultiGameBloc, MultiGameState>(
          builder: (context, gameState) {
            // Filter games by participant
            final participantGames = [
              ...gameState.finishedGames,
              ...gameState.pausedGames,
              if (gameState.activeGame != null) gameState.activeGame!,
            ].where((g) {
              return g.participantIds?.contains(widget.participantId) ?? false;
            }).toList();

            // Sort by date descending
            participantGames.sort((a, b) {
              final dateA = a.date;
              final dateB = b.date;
              return dateB.compareTo(dateA);
            });

            return Scaffold(
              appBar: AppBar(
                title: Text(participant!.name),
                elevation: 0,
              ),
              body: CustomScrollView(
                slivers: [
                  // Stats header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _StatColumn(
                                    label: 'Partidas',
                                    value: '${participant!.totalGamesPlayed}',
                                  ),
                                  _StatColumn(
                                    label: 'Ganadas',
                                    value: '${participant!.totalGamesWon}',
                                  ),
                                  _StatColumn(
                                    label: 'Tasa de Win',
                                    value:
                                        '${(participant!.totalGamesPlayed > 0 ? (participant!.totalGamesWon / participant!.totalGamesPlayed * 100).toStringAsFixed(1) : '0.0')}%',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Historial de Partidas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Games list
                  if (participantGames.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.casino,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay partidas',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final game = participantGames[index];
                          return GameHistoryTile(
                            game: game,
                            showWinner: true,
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
                        childCount: participantGames.length,
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

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
