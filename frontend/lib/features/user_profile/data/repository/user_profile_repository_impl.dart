import 'package:news_app_clean_architecture/core/errors/app_failure.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/models/user_profile_model.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileFirestoreDataSource _firestoreDataSource;
  final UserProfileStorageDataSource _storageDataSource;

  UserProfileRepositoryImpl(this._firestoreDataSource, this._storageDataSource);

  @override
  Future<DataState<UserProfileEntity>> getUserProfile(String uid) async {
    try {
      final profile = await _firestoreDataSource.getUserProfile(uid);
      if (profile == null) {
        return DataFailed(
          const AppFailure.notFound('No encontramos tu perfil.'),
        );
      }
      return DataSuccess(profile.toEntity());
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos cargar tu perfil.', cause: e),
      );
    }
  }

  @override
  Future<DataState<UserProfileEntity>> updateUserProfile(
    UserProfileEntity profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      final updated = await _firestoreDataSource.updateUserProfile(model);
      return DataSuccess(updated.toEntity());
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos actualizar tu perfil.', cause: e),
      );
    }
  }

  @override
  Future<DataState<String>> uploadProfilePhoto(
    String uid,
    String imagePath,
  ) async {
    try {
      final url = await _storageDataSource.uploadProfilePhoto(uid, imagePath);
      return DataSuccess(url);
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos subir tu foto de perfil.', cause: e),
      );
    }
  }

  @override
  Future<DataState<void>> deleteProfilePhoto(String uid) async {
    try {
      await _storageDataSource.deleteProfilePhoto(uid);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos borrar tu foto de perfil.', cause: e),
      );
    }
  }
}
