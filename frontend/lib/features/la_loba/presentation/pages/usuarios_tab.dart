import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/widgets/participant_list_item.dart';

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({Key? key}) : super(key: key);

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  @override
  void initState() {
    super.initState();
    context.read<ParticipantBloc>().add(FetchAllParticipantsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticipantBloc, ParticipantState>(
      builder: (context, state) {
        if (state.status == ParticipantBlocStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.participants.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay usuarios',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (state.isAdmin) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _showCreateParticipantDialog(context);
                      },
                      child: const Text('Crear Usuario'),
                    ),
                  ],
                ],
              ),
            ),
            floatingActionButton: state.isAdmin
                ? FloatingActionButton(
                    onPressed: () {
                      _showCreateParticipantDialog(context);
                    },
                    child: const Icon(Icons.add),
                  )
                : null,
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ParticipantBloc>().add(FetchAllParticipantsEvent());
            },
            child: ListView.separated(
              itemCount: state.participants.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final participant = state.participants[index];
                return ParticipantListItem(
                  participant: participant,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouteNames.laLobaParticipantDetail,
                      arguments: participant.id,
                    );
                  },
                  isAdmin: state.isAdmin,
                  onDelete: state.isAdmin
                      ? () {
                          _showDeleteConfirmation(context, participant.id);
                        }
                      : null,
                );
              },
            ),
          ),
          floatingActionButton: state.isAdmin
              ? FloatingActionButton(
                  onPressed: () {
                    _showCreateParticipantDialog(context);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  void _showCreateParticipantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Usuario'),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  context.read<ParticipantBloc>().add(
                    CreateParticipantEvent(
                      nameController.text,
                      email: emailController.text.isEmpty
                          ? null
                          : emailController.text,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String participantId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Usuario'),
          content: const Text('¿Estás seguro de que querés eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ParticipantBloc>().add(
                  DeleteParticipantEvent(participantId),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
