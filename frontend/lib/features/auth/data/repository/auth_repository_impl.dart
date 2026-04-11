import 'dart:async';

import 'package:news_app_clean_architecture/core/errors/app_failure.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/data/data_sources/remote/auth_firebase_data_source.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/auth_failure.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<DataState<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.login(email: email, password: password);
      return DataSuccess(user.toEntity());
    } on Exception catch (e) {
      return DataFailed(_mapFailure(e, fallback: 'No pudimos iniciar sesión.'));
    }
  }

  @override
  Future<DataState<UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _dataSource.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      return DataSuccess(user.toEntity());
    } on Exception catch (e) {
      return DataFailed(
        _mapFailure(e, fallback: 'No pudimos crear la cuenta.'),
      );
    }
  }

  @override
  Future<DataState<UserEntity>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return DataSuccess(user.toEntity());
    } on Exception catch (e) {
      return DataFailed(
        _mapFailure(e, fallback: 'No pudimos iniciar con Google.'),
      );
    }
  }

  @override
  Future<DataState<void>> logout() async {
    try {
      await _dataSource.logout();
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(_mapFailure(e, fallback: 'No pudimos cerrar sesión.'));
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _dataSource.getCurrentUser()?.toEntity();
  }

  Exception _mapFailure(Exception error, {required String fallback}) {
    if (error is AuthFailure) {
      return error;
    }

    if (error is TimeoutException) {
      return AppFailure.timeout('La operación tardó demasiado.', cause: error);
    }

    return AppFailure.unexpected(fallback, cause: error);
  }
}
