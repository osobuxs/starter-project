import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';

class ParticipantListItem extends StatelessWidget {
  final ParticipantEntity participant;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ParticipantListItem({
    super.key,
    required this.participant,
    required this.onTap,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = participant.totalGamesPlayed > 0
        ? ((participant.totalGamesWon / participant.totalGamesPlayed) * 100)
            .toStringAsFixed(1)
        : '0.0';

    return ListTile(
      onTap: onTap,
      title: Text(participant.name),
      subtitle: Text(
        'Partidas: ${participant.totalGamesPlayed} | Ganadas: ${participant.totalGamesWon} | Tasa: $winRate%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isAdmin && (onDelete != null || onEdit != null)
          ? PopupMenuButton(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                }
                if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar'),
                ),
              ],
            )
          : null,
    );
  }
}
