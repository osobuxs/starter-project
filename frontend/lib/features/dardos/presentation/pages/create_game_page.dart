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
import 'package:news_app_clean_architecture/features/dardos/domain/usecases/dardos_team_config_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DardosCreateGamePage extends StatefulWidget {
  const DardosCreateGamePage({super.key});

  @override
  State<DardosCreateGamePage> createState() => _DardosCreateGamePageState();
}

class _DardosCreateGamePageState extends State<DardosCreateGamePage> {
  final _gameNameController = TextEditingController();
  final List<String> _selectedPlayerIds = [];

  String _mode = '501';
  bool _teamMode = false;
  bool _doubleOut = false;
  int _sets = 1;
  int _legs = 3;
  bool _isCreating = false;

  // New states for dynamic team configuration
  int _numberOfTeams = 2;
  int _playersPerTeam = 2;
  final Map<int, TextEditingController> _teamNameControllers = {};
  final Map<int, List<String?>> _teamPlayers = {};

  @override
  void initState() {
    super.initState();
    context.read<DardosParticipantBloc>().add(FetchAllParticipantsEvent());
    _initializeTeamData();
  }

  void _initializeTeamData() {
    for (int i = 0; i < _numberOfTeams; i++) {
      _teamNameControllers.putIfAbsent(
        i,
        () => TextEditingController(text: 'Equipo ${i + 1}'),
      );
      if (!_teamPlayers.containsKey(i) || _teamPlayers[i]!.length != _playersPerTeam) {
        final currentList = _teamPlayers[i] ?? [];
        if (currentList.length < _playersPerTeam) {
          currentList.addAll(List.filled(_playersPerTeam - currentList.length, null));
        } else if (currentList.length > _playersPerTeam) {
          currentList.removeRange(_playersPerTeam, currentList.length);
        }
        _teamPlayers[i] = currentList;
      }
    }
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    for (final controller in _teamNameControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
            if (mounted) setState(() => _isCreating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
          builder: (context, participantState) {
            final activeParticipants = participantState.participants
                .where((p) => p.isActive)
                .toList();

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
                  TextField(
                    controller: _gameNameController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Viernes de Dardos',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Jugar por equipos'),
                    subtitle: const Text(
                      'Cada equipo comparte score; las estadísticas se guardan por jugador de forma individual.',
                    ),
                    value: _teamMode,
                    onChanged: (value) {
                      setState(() {
                        _teamMode = value;
                        if (_teamMode) {
                          _initializeTeamData();
                        }
                      });
                    },
                  ),

                  if (_teamMode) ...[
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configuración de Equipos',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _numberOfTeams,
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad de Equipos',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [2, 3, 4, 5, 6].map((n) {
                                      return DropdownMenuItem<int>(
                                        value: n,
                                        child: Text('$n Equipos'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _numberOfTeams = val;
                                          _initializeTeamData();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _playersPerTeam,
                                    decoration: const InputDecoration(
                                      labelText: 'Jugadores por Equipo',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [2, 3, 4].map((m) {
                                      return DropdownMenuItem<int>(
                                        value: m,
                                        child: Text('$m Jugadores'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _playersPerTeam = val;
                                          _initializeTeamData();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Detalle de Equipos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_numberOfTeams, (tIndex) {
                      final teamNameController = _teamNameControllers[tIndex]!;
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: teamNameController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre del Equipo ${tIndex + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_playersPerTeam, (pIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: DropdownButtonFormField<String>(
                                    value: _teamPlayers[tIndex]?[pIndex],
                                    decoration: InputDecoration(
                                      labelText: 'Jugador ${pIndex + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: activeParticipants.map((p) {
                                      return DropdownMenuItem<String>(
                                        value: p.id,
                                        child: Text(p.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _teamPlayers[tIndex]![pIndex] = val;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),

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

                  // Simple mode participant selector
                  if (!_teamMode) ...[
                    const Text(
                      'Seleccionar Jugadores',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (participantState.status ==
                        DardosParticipantStatus.loading)
                      const Center(child: CircularProgressIndicator())
                    else if (activeParticipants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No hay jugadores. Creá algunos en la pestaña Jugadores.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...activeParticipants.map((participant) {
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
                          final name = activeParticipants
                              .firstWhere(
                                (p) => p.id == playerId,
                                orElse: () => activeParticipants.first,
                              )
                              .name;
                          return ListTile(
                            key: ValueKey(playerId),
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(name),
                            trailing: const Icon(Icons.drag_handle),
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isCreating ? null : () => _createGame(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
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
    // Guard against double submission (belt-and-suspenders with the
    // disabled button and the bloc-level _createInFlight guard).
    if (_isCreating) return;

    if (_gameNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    if (!_teamMode) {
      if (_selectedPlayerIds.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná al menos 2 jugadores')),
        );
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      setState(() => _isCreating = true);
      context.read<DardosGameBloc>().add(
            CreateDardosGameEvent(
              name: _gameNameController.text.trim(),
              mode: _mode,
              doubleOut: _mode == 'cricket' ? false : _doubleOut,
              sets: _sets,
              legs: _legs,
              playerIds: List.from(_selectedPlayerIds),
              teamMode: false,
              createdBy: uid,
            ),
          );
      return;
    }

    // Team mode configuration compilation and validation
    final Map<int, List<String>> playersInTeams = {};
    for (int i = 0; i < _numberOfTeams; i++) {
      playersInTeams[i] = (_teamPlayers[i] ?? [])
          .where((id) => id != null)
          .cast<String>()
          .toList();
    }

    final Map<int, String> teamNames = {};
    for (int i = 0; i < _numberOfTeams; i++) {
      final name = _teamNameControllers[i]?.text.trim() ?? '';
      teamNames[i] = name.isEmpty ? 'Equipo ${i + 1}' : name;
    }

    final validator = DardosTeamConfigValidator();
    final validationResult = validator.validate(
      numberOfTeams: _numberOfTeams,
      playersPerTeam: _playersPerTeam,
      teamNames: teamNames,
      playersInTeams: playersInTeams,
    );

    if (!validationResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationResult.errorMessage ?? 'Error de configuración de equipos.')),
      );
      return;
    }

    final teams = validationResult.teams!;
    final playerTeamIds = validationResult.playerTeamIds!;

    // Turn ordering interleaving: Round-robin across teams
    final List<String> orderedPlayerIds = [];
    for (int pIndex = 0; pIndex < _playersPerTeam; pIndex++) {
      for (int tIndex = 0; tIndex < _numberOfTeams; tIndex++) {
        orderedPlayerIds.add(playersInTeams[tIndex]![pIndex]);
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    setState(() => _isCreating = true);
    context.read<DardosGameBloc>().add(
          CreateDardosGameEvent(
            name: _gameNameController.text.trim(),
            mode: _mode,
            doubleOut: _mode == 'cricket' ? false : _doubleOut,
            sets: _sets,
            legs: _legs,
            playerIds: orderedPlayerIds,
            teamMode: true,
            teams: teams,
            playerTeamIds: playerTeamIds,
            createdBy: uid,
          ),
        );
  }
}
