import 'package:news_app_clean_architecture/core/errors/app_failure.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/article_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/favorite_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles_entity.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleFirestoreDataSource _articleFirestoreDataSource;
  final FavoriteFirestoreDataSource _favoriteFirestoreDataSource;

  ArticleRepositoryImpl(
    this._articleFirestoreDataSource,
    this._favoriteFirestoreDataSource,
  );

  @override
  Future<DataState<PaginatedArticlesEntity>> getNewsArticles({
    ArticlePaginationCursor? after,
    DateTime? dateFilter,
  }) async {
    try {
      final paginated = await _articleFirestoreDataSource.getPublishedArticles(
        after: after,
        dateFilter: dateFilter,
      );

      return DataSuccess(paginated.toEntity());
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos cargar las noticias.', cause: e),
      );
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
      return DataFailed(
        AppFailure.unexpected('No pudimos cargar tus favoritos.', cause: e),
      );
    }
  }

  @override
  Future<DataState<ArticleEntity>> getArticleByFirestoreId(
    String articleId,
  ) async {
    try {
      final article = await _articleFirestoreDataSource.getArticleByFirestoreId(
        articleId,
      );

      if (article == null) {
        return DataFailed(
          const AppFailure.notFound('No encontramos la nota solicitada.'),
        );
      }

      return DataSuccess(article.toEntity());
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos cargar la nota.', cause: e),
      );
    }
  }

  @override
  Future<DataState<void>> removeArticle(ArticleEntity article) async {
    try {
      final articleId = article.firestoreId?.trim();
      if (articleId == null || articleId.isEmpty) {
        return DataFailed(
          const AppFailure.validation(
            'El id del artículo es obligatorio para quitar favorito.',
          ),
        );
      }

      await _favoriteFirestoreDataSource.removeFavoriteArticle(articleId);
      return const DataSuccess<void>(null);
    } on Exception catch (e) {
      return DataFailed(
        AppFailure.unexpected('No pudimos quitar el favorito.', cause: e),
      );
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
      return DataFailed(
        AppFailure.unexpected('No pudimos guardar el favorito.', cause: e),
      );
    }
  }
}
