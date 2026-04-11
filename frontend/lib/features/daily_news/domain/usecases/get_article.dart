import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles_entity.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class GetArticlesParams extends Equatable {
  final ArticlePaginationCursor? after;
  final DateTime? dateFilter;

  const GetArticlesParams({this.after, this.dateFilter});

  @override
  List<Object?> get props => [after, dateFilter];
}

class GetArticleUseCase
    implements UseCase<DataState<PaginatedArticlesEntity>, GetArticlesParams> {
  final ArticleRepository _articleRepository;

  GetArticleUseCase(this._articleRepository);

  @override
  Future<DataState<PaginatedArticlesEntity>> call({GetArticlesParams? params}) {
    return _articleRepository.getNewsArticles(
      after: params?.after,
      dateFilter: params?.dateFilter,
    );
  }
}
