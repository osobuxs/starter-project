import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  required String confirmLabel,
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: isDestructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<bool> showAuthenticationRequiredDialog(
  BuildContext context, {
  required String actionLabel,
  String successMessage = 'Después te llevamos automáticamente.',
}) async {
  return showConfirmationDialog(
    context,
    title: 'Necesitás iniciar sesión',
    message:
        'Para $actionLabel primero necesitás iniciar sesión. $successMessage',
    confirmLabel: 'Ir al login',
  );
}

Future<bool> showDiscardChangesDialog(BuildContext context) async {
  return showConfirmationDialog(
    context,
    title: 'Tenés cambios sin guardar',
    message:
        'Si salís ahora, vas a perder los cambios pendientes. ¿Querés salir igual?',
    cancelLabel: 'Seguir editando',
    confirmLabel: 'Salir sin guardar',
    isDestructive: true,
  );
}
