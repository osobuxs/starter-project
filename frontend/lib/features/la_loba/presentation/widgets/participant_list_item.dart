import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';

class ParticipantListItem extends StatelessWidget {
  final ParticipantEntity participant;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const ParticipantListItem({
    Key? key,
    required this.participant,
    required this.onTap,
    required this.isAdmin,
    this.onDelete,
  }) : super(key: key);

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
      trailing: isAdmin && onDelete != null
          ? PopupMenuButton(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
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
