import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  Future<DataState<UserEntity>> Function({
    required String email,
    required String password,
  })?
  onLogin;

  Future<DataState<UserEntity>> Function({
    required String email,
    required String password,
    required String displayName,
  })?
  onRegister;

  Future<DataState<UserEntity>> Function()? onSignInWithGoogle;
  Future<DataState<void>> Function()? onLogout;
  Future<UserEntity?> Function()? onGetCurrentUser;

  @override
  Future<UserEntity?> getCurrentUser() {
    final handler = onGetCurrentUser;
    if (handler == null) {
      return Future<UserEntity?>.value(null);
    }
    return handler();
  }

  @override
  Future<DataState<UserEntity>> login({
    required String email,
    required String password,
  }) {
    final handler = onLogin;
    if (handler == null) {
      return Future<DataState<UserEntity>>.value(
        DataFailed(Exception('onLogin not configured')),
      );
    }
    return handler(email: email, password: password);
  }

  @override
  Future<DataState<void>> logout() {
    final handler = onLogout;
    if (handler == null) {
      return Future<DataState<void>>.value(
        DataFailed(Exception('onLogout not configured')),
      );
    }
    return handler();
  }

  @override
  Future<DataState<UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    final handler = onRegister;
    if (handler == null) {
      return Future<DataState<UserEntity>>.value(
        DataFailed(Exception('onRegister not configured')),
      );
    }
    return handler(email: email, password: password, displayName: displayName);
  }

  @override
  Future<DataState<UserEntity>> signInWithGoogle() {
    final handler = onSignInWithGoogle;
    if (handler == null) {
      return Future<DataState<UserEntity>>.value(
        DataFailed(Exception('onSignInWithGoogle not configured')),
      );
    }
    return handler();
  }
}
