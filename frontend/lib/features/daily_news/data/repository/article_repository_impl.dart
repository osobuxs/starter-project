import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/article_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/favorite_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleFirestoreDataSource _articleFirestoreDataSource;
  final FavoriteFirestoreDataSource _favoriteFirestoreDataSource;

  ArticleRepositoryImpl(
    this._articleFirestoreDataSource,
    this._favoriteFirestoreDataSource,
  );

  @override
  Future<DataState<List<ArticleEntity>>> getNewsArticles({
    required int page,
    DateTime? dateFilter,
  }) async {
    try {
      final articles = await _articleFirestoreDataSource.getPublishedArticles(
        page: page,
        dateFilter: dateFilter,
      );

      return DataSuccess(
        articles.map((article) => article.toEntity()).toList(),
      );
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<ArticleEntity>>> getSavedArticles() async {
    try {
      final favorites = await _favoriteFirestoreDataSource
          .getFavoriteArticles();
      return DataSuccess(
        favorites.map((article) => article.toEntity()).toList(),
      );
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> removeArticle(ArticleEntity article) async {
    try {
      final articleId = article.firestoreId?.trim();
      if (articleId == null || articleId.isEmpty) {
        return DataFailed(
          Exception('Article id is required to remove favorite'),
        );
      }

      await _favoriteFirestoreDataSource.removeFavoriteArticle(articleId);
      return const DataSuccess<void>(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> saveArticle(ArticleEntity article) async {
    try {
      await _favoriteFirestoreDataSource.saveFavoriteArticle(
        ArticleModel.fromEntity(article),
      );
      return const DataSuccess<void>(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
