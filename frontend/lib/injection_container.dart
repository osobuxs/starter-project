import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:news_app_clean_architecture/features/auth/data/data_sources/remote/auth_firebase_data_source.dart';
import 'package:news_app_clean_architecture/features/auth/data/repository/auth_repository_impl.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/logout_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/register_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/repository/user_profile_repository_impl.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/update_user_profile_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_cubit.dart';
import 'features/daily_news/data/data_sources/local/app_database.dart';
import 'features/daily_news/domain/usecases/get_saved_article.dart';
import 'features/daily_news/domain/usecases/remove_article.dart';
import 'features/daily_news/domain/usecases/save_article.dart';
import 'features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final database = await $FloorAppDatabase
      .databaseBuilder('app_database.db')
      .build();
  sl.registerSingleton<AppDatabase>(database);

  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Dio
  sl.registerSingleton<Dio>(Dio());

  // Dependencies
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));
  sl.registerLazySingleton<AuthFirebaseDataSource>(
    () => AuthFirebaseDataSourceImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<UserProfileFirestoreDataSource>(
    () => UserProfileFirestoreDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<UserProfileStorageDataSource>(
    () => UserProfileStorageDataSourceImpl(sl()),
  );

  sl.registerSingleton<ArticleRepository>(ArticleRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(sl(), sl()),
  );

  //UseCases
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));

  sl.registerSingleton<GetSavedArticleUseCase>(GetSavedArticleUseCase(sl()));

  sl.registerSingleton<SaveArticleUseCase>(SaveArticleUseCase(sl()));

  sl.registerSingleton<RemoveArticleUseCase>(RemoveArticleUseCase(sl()));
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(sl()));
  sl.registerLazySingleton<SignInWithGoogleUseCase>(
    () => SignInWithGoogleUseCase(sl()),
  );
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl()),
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

  //Blocs
  sl.registerFactory<RemoteArticlesBloc>(() => RemoteArticlesBloc(sl()));

  sl.registerFactory<LocalArticleBloc>(
    () => LocalArticleBloc(sl(), sl(), sl()),
  );
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory<UserProfileCubit>(
    () => UserProfileCubit(
      getUserProfile: sl(),
      updateUserProfile: sl(),
      uploadPhoto: sl(),
    ),
  );
}
