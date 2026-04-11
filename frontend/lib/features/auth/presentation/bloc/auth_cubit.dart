import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
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
            _mapFirebaseError(result.error),
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
        AuthError(
          _mapFirebaseError(error),
          source: source,
          requestId: requestId,
        ),
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
            _mapFirebaseError(result.error),
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
        AuthError(
          _mapFirebaseError(error),
          source: source,
          requestId: requestId,
        ),
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
            _mapFirebaseError(result.error),
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
        AuthError(
          _mapFirebaseError(error),
          source: source,
          requestId: requestId,
        ),
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
        emit(AuthError(_mapFirebaseError(result.error)));
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

  String _mapFirebaseError(Exception? error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe una cuenta con ese email.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese email. Probá iniciar sesión en lugar de registrarte.';
        case 'email-already-in-use-friendly':
          return 'Ya existe una cuenta con ese email. Probá iniciar sesión en lugar de registrarte.';
        case 'email-already-in-use-google':
          return 'Ese email ya está asociado a una cuenta creada con Google. Usá “Continuar con Google” para ingresar.';
        case 'email-already-in-use-provider':
          return 'Ese email ya está asociado a una cuenta creada con otro proveedor. Iniciá sesión con ese método para continuar.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'invalid-email':
          return 'El email no es válido.';
        case 'invalid-credential':
          return 'Credenciales incorrectas.';
        case 'account-exists-with-different-credential':
          return 'Ese email ya está vinculado a otro método de acceso. Probá ingresar con el proveedor original.';
        default:
          return error.message ?? 'Ocurrió un error. Intentá de nuevo.';
      }
    }
    return 'Ocurrió un error. Intentá de nuevo.';
  }
}
