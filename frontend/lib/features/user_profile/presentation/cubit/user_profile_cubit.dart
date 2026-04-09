import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/update_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final GetUserProfileUseCase _getUserProfile;
  final UpdateUserProfileUseCase _updateUserProfile;
  final UploadProfilePhotoUseCase _uploadPhoto;

  UserProfileCubit({
    required GetUserProfileUseCase getUserProfile,
    required UpdateUserProfileUseCase updateUserProfile,
    required UploadProfilePhotoUseCase uploadPhoto,
  }) : _getUserProfile = getUserProfile,
       _updateUserProfile = updateUserProfile,
       _uploadPhoto = uploadPhoto,
       super(UserProfileInitial());

  Future<void> loadProfile(String uid) async {
    emit(UserProfileLoading());
    final result = await _getUserProfile(
      params: GetUserProfileParams(uid: uid),
    );

    if (result is DataSuccess<UserProfileEntity>) {
      emit(UserProfileLoaded(result.data!));
    }

    if (result is DataFailed<UserProfileEntity>) {
      if (result.error.toString().contains('Profile not found')) {
        emit(UserProfileNotFound());
      } else {
        emit(const UserProfileError('Failed to load profile'));
      }
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    int? age,
  }) async {
    final currentState = state;
    if (currentState is! UserProfileLoaded) return;

    emit(UserProfileUpdating(currentState.profile));

    final updatedProfile = currentState.profile.copyWith(name: name, age: age);

    final result = await _updateUserProfile(
      params: UpdateUserProfileParams(profile: updatedProfile),
    );

    if (result is DataSuccess<UserProfileEntity>) {
      emit(UserProfileLoaded(result.data!));
    }

    if (result is DataFailed<UserProfileEntity>) {
      emit(const UserProfileError('Failed to update profile'));
    }
  }

  Future<void> uploadPhoto({
    required String uid,
    required String imagePath,
  }) async {
    final currentState = state;
    if (currentState is! UserProfileLoaded) return;

    emit(UserProfilePhotoUploading(currentState.profile));

    final uploadResult = await _uploadPhoto(
      params: UploadProfilePhotoParams(uid: uid, imagePath: imagePath),
    );

    if (uploadResult is DataFailed<String>) {
      emit(const UserProfileError('Failed to upload photo'));
      return;
    }

    final updatedProfile = currentState.profile.copyWith(
      photoUrl: uploadResult.data,
    );
    final updateResult = await _updateUserProfile(
      params: UpdateUserProfileParams(profile: updatedProfile),
    );

    if (updateResult is DataSuccess<UserProfileEntity>) {
      emit(UserProfileLoaded(updateResult.data!));
    }

    if (updateResult is DataFailed<UserProfileEntity>) {
      emit(const UserProfileError('Failed to save photo URL'));
    }
  }
}
