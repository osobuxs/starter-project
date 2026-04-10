import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  Future<DataState<UserProfileEntity>> getUserProfile(String uid);
  Future<DataState<UserProfileEntity>> updateUserProfile(
    UserProfileEntity profile,
  );
  Future<DataState<String>> uploadProfilePhoto(String uid, String imagePath);
  Future<DataState<void>> deleteProfilePhoto(String uid);
}
