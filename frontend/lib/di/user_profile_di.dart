import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/repository/user_profile_repository_impl.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/delete_profile_photo_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/update_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_cubit.dart';

void registerUserProfileDependencies(GetIt sl) {
  sl.registerLazySingleton<UserProfileFirestoreDataSource>(
    () => UserProfileFirestoreDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<UserProfileStorageDataSource>(
    () => UserProfileStorageDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton<GetUserProfileUseCase>(
    () => GetUserProfileUseCase(sl()),
  );
  sl.registerLazySingleton<UpdateUserProfileUseCase>(
    () => UpdateUserProfileUseCase(sl()),
  );
  sl.registerLazySingleton<UploadProfilePhotoUseCase>(
    () => UploadProfilePhotoUseCase(sl()),
  );
  sl.registerLazySingleton<DeleteProfilePhotoUseCase>(
    () => DeleteProfilePhotoUseCase(sl()),
  );

  sl.registerFactory<UserProfileCubit>(
    () => UserProfileCubit(
      getUserProfile: sl(),
      updateUserProfile: sl(),
      uploadPhoto: sl(),
      deletePhoto: sl(),
    ),
  );
}
