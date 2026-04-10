import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/update_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  static const Duration _profileTimeout = Duration(seconds: 12);

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
    try {
      final result = await _getUserProfile(
        params: GetUserProfileParams(uid: uid),
      ).timeout(_profileTimeout);

      if (result is DataSuccess<UserProfileEntity>) {
        emit(UserProfileLoaded(result.data!));
      }

      if (result is DataFailed<UserProfileEntity>) {
        if (result.error.toString().contains('Profile not found')) {
          emit(UserProfileNotFound());
        } else {
          emit(
            const UserProfileError(
              'No se pudo cargar tu perfil. Intentá nuevamente.',
            ),
          );
        }
      }
    } on TimeoutException {
      emit(
        const UserProfileError(
          'Tu perfil tardó demasiado en cargar. Verificá tu conexión e intentá de nuevo.',
        ),
      );
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    int? age,
    String? pendingPhotoPath,
    bool removePhoto = false,
  }) async {
    final currentState = state;
    if (currentState is! UserProfileLoaded) return;

    emit(UserProfileUpdating(currentState.profile));

    try {
      String? photoUrl = currentState.profile.photoUrl;

      final normalizedPendingPhotoPath = pendingPhotoPath?.trim();
      if (normalizedPendingPhotoPath != null &&
          normalizedPendingPhotoPath.isNotEmpty) {
        final uploadResult = await _uploadPhoto(
          params: UploadProfilePhotoParams(
            uid: uid,
            imagePath: normalizedPendingPhotoPath,
          ),
        ).timeout(_profileTimeout);

        if (uploadResult is DataFailed<String>) {
          emit(
            UserProfileError(
              'No se pudo subir la foto. Intentá nuevamente.',
              profile: currentState.profile,
            ),
          );
          return;
        }

        photoUrl = uploadResult.data;
      } else if (removePhoto) {
        photoUrl = null;
      }

      final updatedProfile = currentState.profile.copyWith(
        name: name,
        age: age,
        photoUrl: photoUrl,
      );

      final result = await _updateUserProfile(
        params: UpdateUserProfileParams(profile: updatedProfile),
      ).timeout(_profileTimeout);

      if (result is DataSuccess<UserProfileEntity>) {
        emit(UserProfileLoaded(result.data!));
      }

      if (result is DataFailed<UserProfileEntity>) {
        emit(
          UserProfileError(
            'No se pudieron guardar los cambios. Intentá nuevamente.',
            profile: currentState.profile,
          ),
        );
      }
    } on TimeoutException {
      emit(
        UserProfileError(
          'Guardar los cambios tardó demasiado. Intentá nuevamente.',
          profile: currentState.profile,
        ),
      );
    }
  }
}
