import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';

class JugadoresTab extends StatefulWidget {
  const JugadoresTab({Key? key}) : super(key: key);

  @override
  State<JugadoresTab> createState() => _JugadoresTabState();
}

class _JugadoresTabState extends State<JugadoresTab> {
  @override
  void initState() {
    super.initState();
    context.read<DardosParticipantBloc>().add(FetchAllParticipantsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DardosParticipantBloc, DardosParticipantState>(
      listener: (context, state) {
        if (state.status == DardosParticipantStatus.error &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      child: BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
        builder: (context, state) {
          if (state.status == DardosParticipantStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeParticipants =
              state.participants.where((p) => p.isActive).toList();

          if (activeParticipants.isEmpty) {
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jugadores',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay jugadores registrados.',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                              if (state.isAdmin) ...[
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    _showCreateJugadorDialog(context);
                                  },
                                  child: const Text('Crear Jugador'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: state.isAdmin
                  ? FloatingActionButton(
                      onPressed: () {
                        _showCreateJugadorDialog(context);
                      },
                      child: const Icon(Icons.add),
                    )
                  : null,
            );
          }

          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jugadores',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<DardosParticipantBloc>()
                              .add(FetchAllParticipantsEvent());
                        },
                        child: ListView.separated(
                          itemCount: activeParticipants.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final participant = activeParticipants[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  participant.name
                                      .substring(0, 1)
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(participant.name),
                              subtitle: participant.email != null
                                  ? Text(participant.email!)
                                  : null,
                              trailing: state.isAdmin
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () {
                                        _showDeleteConfirmation(
                                          context,
                                          participant,
                                        );
                                      },
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRouteNames.dardosJugadorDetail,
                                  arguments: participant.id,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: state.isAdmin
                ? FloatingActionButton(
                    onPressed: () {
                      _showCreateJugadorDialog(context);
                    },
                    child: const Icon(Icons.add),
                  )
                : null,
          );
        },
      ),
    );
  }

  void _showCreateJugadorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Crear Jugador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('El nombre no puede estar vacío')),
                  );
                  return;
                }
                final now = DateTime.now().millisecondsSinceEpoch;
                final participant = DardosParticipantEntity(
                  id: '',
                  name: name,
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  isActive: true,
                  createdAt: now,
                  totalGamesPlayed: 0,
                  totalGamesWon: 0,
                  statsByMode: const {},
                );
                context
                    .read<DardosParticipantBloc>()
                    .add(CreateParticipantEvent(participant: participant));
                Navigator.pop(dialogContext);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DardosParticipantEntity participant) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Jugador'),
          content: Text(
              '¿Estás seguro de que querés eliminar a ${participant.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<DardosParticipantBloc>().add(
                      DeleteParticipantEvent(participantId: participant.id),
                    );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
