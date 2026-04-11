import 'package:flutter/services.dart';

class AuthFormValidators {
  static const int maxDisplayNameLength = 50;
  static const int maxEmailLength = 50;
  static const int maxPasswordLength = 50;

  static final RegExp _displayNameCharacterPattern = RegExp(
    r'[A-Za-zÀ-ÖØ-öø-ÿ ]',
  );

  static final RegExp _emailPattern = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );

  static List<TextInputFormatter> get displayNameInputFormatters => [
    FilteringTextInputFormatter.allow(_displayNameCharacterPattern),
    LengthLimitingTextInputFormatter(maxDisplayNameLength),
  ];

  static List<TextInputFormatter> get emailInputFormatters => [
    LengthLimitingTextInputFormatter(maxEmailLength),
  ];

  static List<TextInputFormatter> get passwordInputFormatters => [
    LengthLimitingTextInputFormatter(maxPasswordLength),
  ];

  static String? validateDisplayName(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Ingresá tu nombre';
    }

    if (trimmedValue.length > maxDisplayNameLength) {
      return 'Máximo 50 caracteres';
    }

    final hasInvalidCharacters = trimmedValue
        .split('')
        .any((character) => !_displayNameCharacterPattern.hasMatch(character));

    if (hasInvalidCharacters) {
      return 'Usá solo letras y espacios';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Ingresá tu email';
    }

    if (trimmedValue.length > maxEmailLength) {
      return 'Máximo 50 caracteres';
    }

    final match = _emailPattern.firstMatch(trimmedValue);
    final isExactMatch = match != null && match.group(0) == trimmedValue;

    if (!isExactMatch) {
      return 'Ingresá un email válido';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresá tu contraseña';
    }

    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }

    if (value.length > maxPasswordLength) {
      return 'Máximo 50 caracteres';
    }

    return null;
  }
}
