import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/utils/participant_display.dart';

class GameFinishedPage extends StatefulWidget {
  final String gameId;

  const GameFinishedPage({super.key, required this.gameId});

  @override
  State<GameFinishedPage> createState() => _GameFinishedPageState();
}

class _GameFinishedPageState extends State<GameFinishedPage> {
  @override
  void initState() {
    super.initState();
    final participantBloc = context.read<ParticipantBloc>();
    if (participantBloc.state.participants.isEmpty) {
      participantBloc.add(const FetchAllParticipantsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Juego terminado',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state.status == GameBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = state.game;
          if (game == null) {
            return const Center(child: Text('Error al cargar el juego'));
          }

          final winnerId = game.winnerId;
          final participantIds = game.participantIds;

          return BlocBuilder<ParticipantBloc, ParticipantState>(
            builder: (context, participantState) {
              final participantNames = {
                for (final participant in participantState.participants)
                  participant.id: participant.name,
              };
              final winnerName = winnerId == null
                  ? 'Desconocido'
                  : resolveParticipantName(winnerId, participantNames);

              return Column(
                children: [
                  // Winner banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: Colors.amber.shade100,
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events,
                            size: 48, color: Colors.amber),
                        const SizedBox(height: 8),
                        Text(
                          'Ganador: $winnerName',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Participantes: ${participantIds.length}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  // Participant list
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Participantes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: participantIds.length,
                      itemBuilder: (context, index) {
                        final participantId = participantIds[index];
                        final isWinner = participantId == winnerId;
                        final name = resolveParticipantName(
                          participantId,
                          participantNames,
                        );
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isWinner ? Colors.amber : Colors.grey.shade200,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isWinner ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(name),
                          trailing: isWinner
                              ? const Icon(Icons.emoji_events,
                                  color: Colors.amber)
                              : null,
                        );
                      },
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRouteNames.laLoba,
                                (route) => route.isFirst,
                              );
                            },
                            child: const Text('Volver'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRouteNames.laLobaPlay,
                                arguments: widget.gameId,
                              );
                            },
                            child: const Text('Ver partida'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
