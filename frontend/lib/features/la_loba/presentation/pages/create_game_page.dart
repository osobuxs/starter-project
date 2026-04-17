import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart'
    as game_event;
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final _gameNameController = TextEditingController();
  final List<String> _selectedParticipantIds = [];

  @override
  void initState() {
    super.initState();
    context.read<ParticipantBloc>().add(const FetchAllParticipantsEvent());
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Partida'),
      ),
      body: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state.status == GameBlocStatus.gameCreated &&
              state.game != null) {
            // Reload games in MultiGameBloc
            context.read<MultiGameBloc>().add(LoadGamesEvent());

            Navigator.of(context).pushReplacementNamed(
              AppRouteNames.laLobaPlay,
              arguments: state.game!.id,
            );
          }
          if (state.status == GameBlocStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: BlocBuilder<ParticipantBloc, ParticipantState>(
          builder: (context, participantState) {
            final canCreateGame = participantState.isAdmin;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (!canCreateGame)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Modo lectura: no tenés permisos para crear partidas.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  const Text(
                    'Nombre de la Partida',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gameNameController,
                    enabled: canCreateGame,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Viernes de Loba',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Seleccionar Participantes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (participantState.participants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No hay participantes. Crea algunos en la pestaña Usuarios.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...participantState.participants.map((participant) {
                      final selectedIndex = _selectedParticipantIds.indexOf(
                        participant.id,
                      );
                      final isSelected = selectedIndex != -1;

                      return CheckboxListTile(
                        title: Text(participant.name),
                        subtitle: participant.email != null
                            ? Text(participant.email!)
                            : null,
                        secondary: isSelected
                            ? CircleAvatar(
                                radius: 12,
                                child: Text(
                                  '${selectedIndex + 1}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )
                            : null,
                        value: isSelected,
                        onChanged: canCreateGame
                            ? (_) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedParticipantIds
                                        .remove(participant.id);
                                  } else {
                                    _selectedParticipantIds.add(participant.id);
                                  }
                                });
                              }
                            : null,
                      );
                    }),
                  if (_selectedParticipantIds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Orden de reparto',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reparte primero: ${_participantNameById(participantState.participants, _selectedParticipantIds.first)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedParticipantIds.length,
                      onReorder: canCreateGame
                          ? (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item =
                                    _selectedParticipantIds.removeAt(oldIndex);
                                _selectedParticipantIds.insert(newIndex, item);
                              });
                            }
                          : (_, __) {},
                      itemBuilder: (context, index) {
                        final participantId = _selectedParticipantIds[index];
                        final participantName = _participantNameById(
                          participantState.participants,
                          participantId,
                        );

                        return ListTile(
                          key: ValueKey(participantId),
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(participantName),
                          trailing: const Icon(Icons.drag_handle),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed:
                        canCreateGame ? () => _createGame(context) : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Crear Partida',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _createGame(BuildContext context) {
    final isAdmin = context.read<ParticipantBloc>().state.isAdmin;
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenés permisos para crear partidas')),
      );
      return;
    }

    if (_gameNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un participante')),
      );
      return;
    }

    context.read<GameBloc>().add(
          game_event.CreateGameEvent(
            _gameNameController.text.trim(),
            participantIds: _selectedParticipantIds,
          ),
        );
  }

  String _participantNameById(
    List<ParticipantEntity> participants,
    String id,
  ) {
    for (final participant in participants) {
      if (participant.id == id) return participant.name;
    }
    return 'Participante';
  }
}
