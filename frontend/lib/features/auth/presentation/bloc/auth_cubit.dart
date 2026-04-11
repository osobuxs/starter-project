import 'dart:async';

import 'package:news_app_clean_architecture/core/errors/app_failure.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/auth_failure.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/logout_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/register_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  static const Duration _authTimeout = Duration(seconds: 15);

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  String? _activeTrackedRequestId;
  AuthRequestSource _activeTrackedRequestSource = AuthRequestSource.none;

  AuthCubit(
    this._loginUseCase,
    this._registerUseCase,
    this._signInWithGoogleUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const AuthInitial());

  Future<void> login({
    required String email,
    required String password,
    AuthRequestSource source = AuthRequestSource.none,
    String? requestId,
  }) async {
    _trackRequest(source: source, requestId: requestId);
    emit(AuthLoading(source: source, requestId: requestId));
    try {
      final result = await _loginUseCase(
        params: LoginParams(email: email, password: password),
      ).timeout(_authTimeout);
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      if (result is DataSuccess) {
        emit(
          AuthAuthenticated(result.data!, source: source, requestId: requestId),
        );
      } else {
        emit(
          AuthError(
            _mapAuthError(result.error),
            source: source,
            requestId: requestId,
          ),
        );
      }
    } on TimeoutException {
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      emit(
        AuthError(
          'El inicio de sesión tardó demasiado. Verificá tu conexión e intentá de nuevo.',
          source: source,
          requestId: requestId,
        ),
      );
    } on Exception catch (error) {
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      emit(
        AuthError(_mapAuthError(error), source: source, requestId: requestId),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    AuthRequestSource source = AuthRequestSource.none,
    String? requestId,
  }) async {
    _trackRequest(source: source, requestId: requestId);
    emit(AuthLoading(source: source, requestId: requestId));
    try {
      final result = await _registerUseCase(
        params: RegisterParams(
          email: email,
          password: password,
          displayName: displayName,
        ),
      ).timeout(_authTimeout);
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      if (result is DataSuccess) {
        emit(
          AuthAuthenticated(result.data!, source: source, requestId: requestId),
        );
      } else {
        emit(
          AuthError(
            _mapAuthError(result.error),
            source: source,
            requestId: requestId,
          ),
        );
      }
    } on TimeoutException {
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      emit(
        AuthError(
          'La creación de la cuenta tardó demasiado. Intentá nuevamente en unos segundos.',
          source: source,
          requestId: requestId,
        ),
      );
    } on Exception catch (error) {
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      emit(
        AuthError(_mapAuthError(error), source: source, requestId: requestId),
      );
    }
  }

  Future<void> signInWithGoogle({
    AuthRequestSource source = AuthRequestSource.none,
    String? requestId,
  }) async {
    _trackRequest(source: source, requestId: requestId);
    emit(AuthLoading(source: source, requestId: requestId));
    try {
      final result = await _signInWithGoogleUseCase().timeout(_authTimeout);
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      if (result is DataSuccess) {
        emit(
          AuthAuthenticated(result.data!, source: source, requestId: requestId),
        );
      } else {
        emit(
          AuthError(
            _mapAuthError(result.error),
            source: source,
            requestId: requestId,
          ),
        );
      }
    } on TimeoutException {
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      emit(
        AuthError(
          'Google tardó demasiado en responder. Intentá nuevamente.',
          source: source,
          requestId: requestId,
        ),
      );
    } on Exception catch (error) {
      if (_isStaleRequest(source: source, requestId: requestId)) {
        return;
      }

      emit(
        AuthError(_mapAuthError(error), source: source, requestId: requestId),
      );
    }
  }

  void _trackRequest({
    required AuthRequestSource source,
    required String? requestId,
  }) {
    if (requestId == null) {
      return;
    }

    _activeTrackedRequestSource = source;
    _activeTrackedRequestId = requestId;
  }

  bool _isStaleRequest({
    required AuthRequestSource source,
    required String? requestId,
  }) {
    if (requestId == null) {
      return false;
    }

    return _activeTrackedRequestSource != source ||
        _activeTrackedRequestId != requestId;
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      final result = await _logoutUseCase().timeout(_authTimeout);
      if (result is DataSuccess) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthError(_mapAuthError(result.error)));
      }
    } on TimeoutException {
      emit(
        const AuthError(
          'No se pudo cerrar la sesión a tiempo. Intentá nuevamente.',
        ),
      );
    }
  }

  Future<void> checkCurrentUser() async {
    final user = await _getCurrentUserUseCase();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  String _mapAuthError(Exception? error) {
    if (error is AuthFailure) {
      switch (error.code) {
        case AuthFailureCode.userNotFound:
          return 'No existe una cuenta con ese email.';
        case AuthFailureCode.wrongPassword:
          return 'Contraseña incorrecta.';
        case AuthFailureCode.emailAlreadyInUse:
          return 'Ya existe una cuenta con ese email. Probá iniciar sesión en lugar de registrarte.';
        case AuthFailureCode.emailAlreadyInUseGoogle:
          return 'Ese email ya está asociado a una cuenta creada con Google. Usá “Continuar con Google” para ingresar.';
        case AuthFailureCode.emailAlreadyInUseProvider:
          return 'Ese email ya está asociado a una cuenta creada con otro proveedor. Iniciá sesión con ese método para continuar.';
        case AuthFailureCode.weakPassword:
          return 'La contraseña debe tener al menos 6 caracteres.';
        case AuthFailureCode.invalidEmail:
          return 'El email no es válido.';
        case AuthFailureCode.invalidCredential:
          return 'Credenciales incorrectas.';
        case AuthFailureCode.accountExistsWithDifferentCredential:
          return 'Ese email ya está vinculado a otro método de acceso. Probá ingresar con el proveedor original.';
        case AuthFailureCode.googleAborted:
          return 'Se canceló el inicio con Google. Intentá nuevamente.';
        case AuthFailureCode.network:
          return 'No hay conexión. Verificá tu red e intentá de nuevo.';
        case AuthFailureCode.unknown:
          return error.message ?? 'Ocurrió un error. Intentá de nuevo.';
      }
    }

    if (error is AppFailure) {
      return error.message;
    }

    return 'Ocurrió un error. Intentá de nuevo.';
  }
}
