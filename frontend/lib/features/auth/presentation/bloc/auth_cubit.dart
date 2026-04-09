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
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthCubit(
    this._loginUseCase,
    this._registerUseCase,
    this._signInWithGoogleUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      params: LoginParams(email: email, password: password),
    );
    if (result is DataSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(_mapFirebaseError(result.error)));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const AuthLoading());
    final result = await _registerUseCase(
      params: RegisterParams(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
    if (result is DataSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(_mapFirebaseError(result.error)));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    final result = await _signInWithGoogleUseCase();
    if (result is DataSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(_mapFirebaseError(result.error)));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    final result = await _logoutUseCase();
    if (result is DataSuccess) {
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthError(_mapFirebaseError(result.error)));
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
          return 'Ya existe una cuenta con ese email.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'invalid-email':
          return 'El email no es válido.';
        case 'invalid-credential':
          return 'Credenciales incorrectas.';
        default:
          return error.message ?? 'Ocurrió un error. Intentá de nuevo.';
      }
    }
    return 'Ocurrió un error. Intentá de nuevo.';
  }
}
