import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/data/data_sources/remote/auth_firebase_data_source.dart';
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
      return DataFailed(e);
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
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<UserEntity>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return DataSuccess(user.toEntity());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> logout() async {
    try {
      await _dataSource.logout();
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _dataSource.getCurrentUser()?.toEntity();
  }
}
