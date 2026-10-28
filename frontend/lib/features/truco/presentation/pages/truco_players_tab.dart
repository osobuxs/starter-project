import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_state.dart';

/// Registry of Truco players. Everyone can browse it; only the admin can
/// add, rename or remove players.
class TrucoPlayersTab extends StatelessWidget {
  /// Opens a player's detail page; null hides the navigation.
  final void Function(TrucoParticipant player)? onOpenPlayer;

  const TrucoPlayersTab({super.key, this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrucoParticipantBloc, TrucoParticipantState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final message = _messageFor(state);
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final isLoading = state.status == TrucoParticipantStatus.loading &&
            state.participants.isEmpty;

        return Scaffold(
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.participants.isEmpty
                  ? const _EmptyPlayers()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: state.participants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = state.participants[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF8D5524),
                            foregroundColor: Colors.white,
                            child: Text(
                              player.name.isEmpty
                                  ? '?'
                                  : player.name[0].toUpperCase(),
                            ),
                          ),
                          title: Text(player.name),
                          subtitle: Text(
                            'Jugadas: ${player.totalGamesPlayed} · '
                            'Ganadas: ${player.totalGamesWon}',
                          ),
                          onTap: onOpenPlayer == null
                              ? null
                              : () => onOpenPlayer!(player),
                          trailing: state.isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _showNameDialog(context, player),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          _confirmDelete(context, player),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
          floatingActionButton: state.isAdmin
              ? FloatingActionButton.extended(
                  heroTag: 'truco-add-player',
                  onPressed: () => _showNameDialog(context, null),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Agregar jugador'),
                )
              : null,
        );
      },
    );
  }

  String? _messageFor(TrucoParticipantState state) {
    switch (state.status) {
      case TrucoParticipantStatus.created:
        return 'Jugador agregado';
      case TrucoParticipantStatus.updated:
        return 'Jugador actualizado';
      case TrucoParticipantStatus.deleted:
        return 'Jugador eliminado';
      case TrucoParticipantStatus.error:
        return state.error;
      case TrucoParticipantStatus.initial:
      case TrucoParticipantStatus.loading:
      case TrucoParticipantStatus.loaded:
        return null;
    }
  }

  Future<void> _showNameDialog(
    BuildContext context,
    TrucoParticipant? player,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _PlayerNameDialog(initialName: player?.name),
    );
    if (!context.mounted || name == null) return;

    final bloc = context.read<TrucoParticipantBloc>();
    if (player == null) {
      bloc.add(CreateTrucoParticipantEvent(name));
    } else if (name.trim() != player.name) {
      bloc.add(UpdateTrucoParticipantEvent(player.id, name));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TrucoParticipant player,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar jugador'),
        content: Text(
          '¿Eliminar a ${player.name}? Las partidas jugadas se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<TrucoParticipantBloc>().add(
          DeleteTrucoParticipantEvent(player.id),
        );
  }
}

class _PlayerNameDialog extends StatefulWidget {
  final String? initialName;

  const _PlayerNameDialog({this.initialName});

  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'Nuevo jugador' : 'Editar jugador',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EmptyPlayers extends StatelessWidget {
  const _EmptyPlayers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay jugadores registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
