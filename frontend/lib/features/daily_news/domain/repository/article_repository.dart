import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles_entity.dart';

abstract class ArticleRepository {
  // API methods
  Future<DataState<PaginatedArticlesEntity>> getNewsArticles({
    ArticlePaginationCursor? after,
    DateTime? dateFilter,
  });

  // Favorites methods
  Future<DataState<List<ArticleEntity>>> getSavedArticles();

  Future<DataState<ArticleEntity>> getArticleByFirestoreId(String articleId);

  Future<DataState<void>> saveArticle(ArticleEntity article);

  Future<DataState<void>> removeArticle(ArticleEntity article);
}
