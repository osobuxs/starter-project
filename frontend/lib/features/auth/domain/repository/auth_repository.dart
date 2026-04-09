import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<DataState<UserEntity>> login({
    required String email,
    required String password,
  });

  Future<DataState<UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<DataState<UserEntity>> signInWithGoogle();

  Future<DataState<void>> logout();

  Future<UserEntity?> getCurrentUser();
}
