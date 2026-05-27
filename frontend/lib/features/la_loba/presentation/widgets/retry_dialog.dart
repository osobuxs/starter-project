import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';

class RetryDialog extends StatelessWidget {
  final PlayerEntity player;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RetryDialog({
    super.key,
    required this.player,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Retry disponible'),
      content: Text(
        '${player.name} llegó a ${player.totalScore} puntos.\n\n'
        '¿Querés usar el retry? Tu puntaje se va a reiniciar al del '
        'jugador más cercano a 100.',
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('Rechazar'),
        ),
        ElevatedButton(
          onPressed: onAccept,
          child: const Text('Aceptar retry'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required PlayerEntity player,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RetryDialog(
        player: player,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }
}
