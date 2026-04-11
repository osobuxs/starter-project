import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles_entity.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';

class PaginatedArticlesModel {
  final List<ArticleModel> articles;
  final ArticlePaginationCursor? nextCursor;
  final bool hasReachedMax;

  const PaginatedArticlesModel({
    required this.articles,
    required this.nextCursor,
    required this.hasReachedMax,
  });

  PaginatedArticlesEntity toEntity() {
    return PaginatedArticlesEntity(
      articles: articles.map((article) => article.toEntity()).toList(),
      nextCursor: nextCursor,
      hasReachedMax: hasReachedMax,
    );
  }
}
