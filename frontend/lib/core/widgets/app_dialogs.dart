import 'package:flutter/material.dart';

Future<bool> showAuthenticationRequiredDialog(
  BuildContext context, {
  required String actionLabel,
  String successMessage = 'Después te llevamos automáticamente.',
}) async {
  final shouldContinue = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Necesitás iniciar sesión'),
        content: Text(
          'Para $actionLabel primero necesitás iniciar sesión. $successMessage',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ir al login'),
          ),
        ],
      );
    },
  );

  return shouldContinue ?? false;
}

Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final shouldLeave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Tenés cambios sin guardar'),
        content: const Text(
          'Si salís ahora, vas a perder los cambios pendientes. ¿Querés salir igual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir editando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir sin guardar'),
          ),
        ],
      );
    },
  );

  return shouldLeave ?? false;
}
