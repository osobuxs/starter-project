import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';

class PaginatedArticlesEntity extends Equatable {
  final List<ArticleEntity> articles;
  final ArticlePaginationCursor? nextCursor;
  final bool hasReachedMax;

  const PaginatedArticlesEntity({
    required this.articles,
    required this.nextCursor,
    required this.hasReachedMax,
  });

  @override
  List<Object?> get props => [articles, nextCursor, hasReachedMax];
}
