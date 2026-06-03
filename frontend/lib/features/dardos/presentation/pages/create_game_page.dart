import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DardosCreateGamePage extends StatefulWidget {
  const DardosCreateGamePage({super.key});

  @override
  State<DardosCreateGamePage> createState() => _DardosCreateGamePageState();
}

class _DardosCreateGamePageState extends State<DardosCreateGamePage> {
  final _gameNameController = TextEditingController();
  final _team1NameController = TextEditingController(text: 'Equipo 1');
  final _team2NameController = TextEditingController(text: 'Equipo 2');
  final List<String> _selectedPlayerIds = [];

  String _mode = '501';
  bool _teamMode = false;
  bool _doubleOut = false;
  int _sets = 1;
  int _legs = 3;

  @override
  void initState() {
    super.initState();
    context.read<DardosParticipantBloc>().add(FetchAllParticipantsEvent());
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _team1NameController.dispose();
    _team2NameController.dispose();
    super.dispose();
  }

  String _teamSlotLabel(int index) {
    const labels = [
      'Equipo 1 · Jugador 1',
      'Equipo 2 · Jugador 1',
      'Equipo 1 · Jugador 2',
      'Equipo 2 · Jugador 2',
    ];
    return index >= 0 && index < labels.length ? labels[index] : 'Jugador';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Partida')),
      body: BlocListener<DardosGameBloc, DardosGameState>(
        listener: (context, state) {
          if (state.status == DardosGameStatus.gameCreated &&
              state.game != null) {
            context.read<DardosMultiGameBloc>().add(LoadGamesEvent());
            Navigator.of(context).pushReplacementNamed(
              AppRouteNames.dardosPlay,
              arguments: state.game!.id,
            );
          }
          if (state.status == DardosGameStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
          builder: (context, participantState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Game name
                  const Text(
                    'Nombre de la Partida',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('Jugar por equipos 2 vs 2'),
                    subtitle: const Text(
                      'Cada equipo comparte score; las estadísticas se guardan por jugador.',
                    ),
                    value: _teamMode,
                    onChanged: (value) {
                      setState(() {
                        _teamMode = value;
                        if (_teamMode && _selectedPlayerIds.length > 4) {
                          _selectedPlayerIds.removeRange(
                            4,
                            _selectedPlayerIds.length,
                          );
                        }
                      });
                    },
                  ),

                  if (_teamMode) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _team1NameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Equipo 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _team2NameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Equipo 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seleccioná 4 jugadores y ordenalos así: Equipo 1 J1, Equipo 2 J1, Equipo 1 J2, Equipo 2 J2.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gameNameController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Viernes de Dardos',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),

                  // Mode selector
                  const Text(
                    'Modo de juego',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '501', label: Text('501')),
                      ButtonSegment(value: '301', label: Text('301')),
                      ButtonSegment(value: 'cricket', label: Text('Cricket')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _mode = selected.first;
                        if (_mode == 'cricket') {
                          _doubleOut = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Double-out toggle (disabled for cricket)
                  if (_mode != 'cricket')
                    SwitchListTile(
                      title: const Text('Double out'),
                      subtitle:
                          const Text('Requiere doble para terminar el leg'),
                      value: _doubleOut,
                      onChanged: (val) {
                        setState(() => _doubleOut = val);
                      },
                    ),
                  const SizedBox(height: 8),

                  // Sets stepper
                  // Sets stepper (odd only — to avoid ties)
                  Row(
                    children: [
                      const Text('Sets (impar):',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed:
                            _sets > 1 ? () => setState(() => _sets -= 2) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_sets', style: const TextStyle(fontSize: 18)),
                      IconButton(
                        onPressed: () => setState(() => _sets += 2),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),

                  // Legs stepper (odd only — to avoid ties)
                  Row(
                    children: [
                      const Text('Legs (impar):',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed:
                            _legs > 1 ? () => setState(() => _legs -= 2) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_legs', style: const TextStyle(fontSize: 18)),
                      IconButton(
                        onPressed: () => setState(() => _legs += 2),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Participants
                  const Text(
                    'Seleccionar Jugadores',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (participantState.status ==
                      DardosParticipantStatus.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (participantState.participants
                      .where((p) => p.isActive)
                      .isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No hay jugadores. Creá algunos en la pestaña Jugadores.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...participantState.participants
                        .where((p) => p.isActive)
                        .map((participant) {
                      final selectedIndex =
                          _selectedPlayerIds.indexOf(participant.id);
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
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              _selectedPlayerIds.remove(participant.id);
                            } else {
                              if (_teamMode && _selectedPlayerIds.length >= 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'En 2 vs 2 seleccioná exactamente 4 jugadores',
                                    ),
                                  ),
                                );
                                return;
                              }
                              _selectedPlayerIds.add(participant.id);
                            }
                          });
                        },
                      );
                    }),

                  if (_selectedPlayerIds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Orden de tiro',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedPlayerIds.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _selectedPlayerIds.removeAt(oldIndex);
                          _selectedPlayerIds.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final playerId = _selectedPlayerIds[index];
                        final name = participantState.participants
                            .firstWhere(
                              (p) => p.id == playerId,
                              orElse: () => participantState.participants.first,
                            )
                            .name;
                        return ListTile(
                          key: ValueKey(playerId),
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(name),
                          subtitle:
                              _teamMode ? Text(_teamSlotLabel(index)) : null,
                          trailing: const Icon(Icons.drag_handle),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () => _createGame(context),
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
    if (_gameNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }
    if (_selectedPlayerIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná al menos 2 jugadores')),
      );
      return;
    }
    if (_teamMode && _selectedPlayerIds.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Para equipos 2 vs 2 seleccioná exactamente 4 jugadores'),
        ),
      );
      return;
    }

    final teams = _teamMode
        ? [
            {
              'id': 'team_1',
              'name': _team1NameController.text.trim().isEmpty
                  ? 'Equipo 1'
                  : _team1NameController.text.trim(),
              'playerIds': [_selectedPlayerIds[0], _selectedPlayerIds[2]],
            },
            {
              'id': 'team_2',
              'name': _team2NameController.text.trim().isEmpty
                  ? 'Equipo 2'
                  : _team2NameController.text.trim(),
              'playerIds': [_selectedPlayerIds[1], _selectedPlayerIds[3]],
            },
          ]
        : const <Map<String, dynamic>>[];
    final playerTeamIds = _teamMode
        ? <String, String>{
            _selectedPlayerIds[0]: 'team_1',
            _selectedPlayerIds[2]: 'team_1',
            _selectedPlayerIds[1]: 'team_2',
            _selectedPlayerIds[3]: 'team_2',
          }
        : const <String, String>{};

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    context.read<DardosGameBloc>().add(
          CreateDardosGameEvent(
            name: _gameNameController.text.trim(),
            mode: _mode,
            doubleOut: _mode == 'cricket' ? false : _doubleOut,
            sets: _sets,
            legs: _legs,
            playerIds: List.from(_selectedPlayerIds),
            teamMode: _teamMode,
            teams: teams,
            playerTeamIds: playerTeamIds,
            createdBy: uid,
          ),
        );
  }
}
