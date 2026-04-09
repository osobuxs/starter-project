import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/data/data_sources/article_authoring_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/articles/data/data_sources/article_authoring_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/articles/data/models/article_authoring_model.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class ArticleAuthoringRepositoryImpl implements ArticleAuthoringRepository {
  final ArticleAuthoringFirestoreDataSource _firestoreDataSource;
  final ArticleAuthoringStorageDataSource _storageDataSource;

  ArticleAuthoringRepositoryImpl(
    this._firestoreDataSource,
    this._storageDataSource,
  );

  @override
  Future<DataState<ArticleAuthoringEntity>> saveDraft(
    ArticleAuthoringEntity article,
  ) async {
    try {
      final draft = await _firestoreDataSource.saveDraft(
        ArticleAuthoringModel.fromEntity(article),
      );
      return DataSuccess(draft.toEntity());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<ArticleAuthoringEntity>> publishArticle(
    ArticleAuthoringEntity article,
  ) async {
    try {
      final publishedArticle = await _firestoreDataSource.publishArticle(
        ArticleAuthoringModel.fromEntity(article),
      );
      return DataSuccess(publishedArticle.toEntity());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<String>> uploadArticleImage(
    String authorId,
    String imagePath,
  ) async {
    try {
      final imageUrl = await _storageDataSource.uploadArticleImage(
        authorId,
        imagePath,
      );
      return DataSuccess(imageUrl);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<ArticleAuthoringEntity>> getArticleById(
    String articleId,
  ) async {
    try {
      final article = await _firestoreDataSource.getArticleById(articleId);
      return DataSuccess(article.toEntity());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<ArticleAuthoringEntity>>> getArticlesByAuthorId(
    String authorId,
  ) async {
    try {
      final articles = await _firestoreDataSource.getArticlesByAuthorId(
        authorId,
      );
      return DataSuccess(
        articles.map((article) => article.toEntity()).toList(),
      );
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<ArticleAuthoringEntity>> updateArticleActiveState(
    ArticleAuthoringEntity article,
  ) async {
    try {
      final updatedArticle = await _firestoreDataSource
          .updateArticleActiveState(ArticleAuthoringModel.fromEntity(article));
      return DataSuccess(updatedArticle.toEntity());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
