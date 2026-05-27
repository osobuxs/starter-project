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
  const DardosCreateGamePage({Key? key}) : super(key: key);

  @override
  State<DardosCreateGamePage> createState() => _DardosCreateGamePageState();
}

class _DardosCreateGamePageState extends State<DardosCreateGamePage> {
  final _gameNameController = TextEditingController();
  final List<String> _selectedPlayerIds = [];

  String _mode = '501';
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '501', label: Text('501')),
                      ButtonSegment(value: '301', label: Text('301')),
                      ButtonSegment(
                          value: 'cricket', label: Text('Cricket')),
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
                      subtitle: const Text(
                          'Requiere doble para terminar el leg'),
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
                        onPressed: _sets > 1
                            ? () => setState(() => _sets -= 2)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_sets',
                          style: const TextStyle(fontSize: 18)),
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
                        onPressed: _legs > 1
                            ? () => setState(() => _legs -= 2)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_legs',
                          style: const TextStyle(fontSize: 18)),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (participantState.status == DardosParticipantStatus.loading)
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedPlayerIds.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item =
                              _selectedPlayerIds.removeAt(oldIndex);
                          _selectedPlayerIds.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final playerId = _selectedPlayerIds[index];
                        final name = participantState.participants
                            .firstWhere(
                              (p) => p.id == playerId,
                              orElse: () => participantState
                                  .participants.first,
                            )
                            .name;
                        return ListTile(
                          key: ValueKey(playerId),
                          leading: CircleAvatar(
                              child: Text('${index + 1}')),
                          title: Text(name),
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
        const SnackBar(
            content: Text('El nombre no puede estar vacío')),
      );
      return;
    }
    if (_selectedPlayerIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seleccioná al menos 2 jugadores')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    context.read<DardosGameBloc>().add(
          CreateDardosGameEvent(
            name: _gameNameController.text.trim(),
            mode: _mode,
            doubleOut: _mode == 'cricket' ? false : _doubleOut,
            sets: _sets,
            legs: _legs,
            playerIds: List.from(_selectedPlayerIds),
            createdBy: uid,
          ),
        );
  }
}
