import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/features/articles/data/data_sources/article_authoring_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/articles/data/data_sources/article_authoring_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/articles/data/repository/article_authoring_repository_impl.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_article_by_id_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_my_articles_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/save_article_draft_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/update_article_active_state_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/upload_article_image_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_orchestrator.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_cubit.dart';

void registerArticlesDependencies(GetIt sl) {
  sl.registerLazySingleton<ArticleAuthoringFirestoreDataSource>(
    () => ArticleAuthoringFirestoreDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ArticleAuthoringStorageDataSource>(
    () => ArticleAuthoringStorageDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ArticleAuthoringRepository>(
    () => ArticleAuthoringRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton<SaveArticleDraftUseCase>(
    () => SaveArticleDraftUseCase(sl()),
  );
  sl.registerLazySingleton<PublishArticleUseCase>(
    () => PublishArticleUseCase(sl()),
  );
  sl.registerLazySingleton<UploadArticleImageUseCase>(
    () => UploadArticleImageUseCase(sl()),
  );
  sl.registerLazySingleton<GetArticleByIdUseCase>(
    () => GetArticleByIdUseCase(sl()),
  );
  sl.registerLazySingleton<GetMyArticlesUseCase>(
    () => GetMyArticlesUseCase(sl()),
  );
  sl.registerLazySingleton<UpdateArticleActiveStateUseCase>(
    () => UpdateArticleActiveStateUseCase(sl()),
  );

  sl.registerLazySingleton<CreateEditArticleOrchestrator>(
    () => CreateEditArticleOrchestrator(
      saveArticleDraft: sl(),
      publishArticle: sl(),
      uploadArticleImage: sl(),
      getArticleById: sl(),
      getCurrentUser: sl(),
      getUserProfile: sl(),
    ),
  );

  sl.registerFactory<CreateEditArticleCubit>(
    () => CreateEditArticleCubit(orchestrator: sl()),
  );
  sl.registerFactory<MyNotesCubit>(
    () => MyNotesCubit(
      getCurrentUser: sl(),
      getMyArticles: sl(),
      publishArticle: sl(),
      updateArticleActiveState: sl(),
    ),
  );
}
