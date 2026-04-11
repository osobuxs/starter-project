// Minimal hand-written test doubles to avoid build_runner dependency in CI/local.

import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/logout_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/register_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/sign_in_with_google_usecase.dart';

class MockLoginUseCase implements LoginUseCase {
  Future<DataState<UserEntity>> Function({LoginParams? params})? handler;

  @override
  Future<DataState<UserEntity>> call({LoginParams? params}) {
    final current = handler;
    if (current == null) {
      return Future<DataState<UserEntity>>.value(
        DataFailed(Exception('MockLoginUseCase.handler not configured')),
      );
    }
    return current(params: params);
  }
}

class MockRegisterUseCase implements RegisterUseCase {
  Future<DataState<UserEntity>> Function({RegisterParams? params})? handler;

  @override
  Future<DataState<UserEntity>> call({RegisterParams? params}) {
    final current = handler;
    if (current == null) {
      return Future<DataState<UserEntity>>.value(
        DataFailed(Exception('MockRegisterUseCase.handler not configured')),
      );
    }
    return current(params: params);
  }
}

class MockSignInWithGoogleUseCase implements SignInWithGoogleUseCase {
  Future<DataState<UserEntity>> Function()? handler;

  @override
  Future<DataState<UserEntity>> call() {
    final current = handler;
    if (current == null) {
      return Future<DataState<UserEntity>>.value(
        DataFailed(
          Exception('MockSignInWithGoogleUseCase.handler not configured'),
        ),
      );
    }
    return current();
  }
}

class MockLogoutUseCase implements LogoutUseCase {
  Future<DataState<void>> Function()? handler;

  @override
  Future<DataState<void>> call() {
    final current = handler;
    if (current == null) {
      return Future<DataState<void>>.value(
        DataFailed(Exception('MockLogoutUseCase.handler not configured')),
      );
    }
    return current();
  }
}

class MockGetCurrentUserUseCase implements GetCurrentUserUseCase {
  Future<UserEntity?> Function({void params})? handler;

  @override
  Future<UserEntity?> call({void params}) {
    final current = handler;
    if (current == null) {
      return Future<UserEntity?>.value(null);
    }
    return current(params: params);
  }
}
