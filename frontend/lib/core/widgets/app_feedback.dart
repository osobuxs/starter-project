import 'package:flutter/material.dart';

enum AppSnackBarVariant { info, success, error }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarVariant variant = AppSnackBarVariant.info,
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: _backgroundColorFor(variant),
        content: Text(message),
      ),
    );
}

Color? _backgroundColorFor(AppSnackBarVariant variant) {
  switch (variant) {
    case AppSnackBarVariant.info:
      return null;
    case AppSnackBarVariant.success:
      return Colors.black87;
    case AppSnackBarVariant.error:
      return Colors.red.shade700;
  }
}
