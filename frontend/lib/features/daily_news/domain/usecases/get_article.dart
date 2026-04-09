import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class GetArticlesParams extends Equatable {
  final int page;
  final DateTime? dateFilter;

  const GetArticlesParams({required this.page, this.dateFilter});

  @override
  List<Object?> get props => [page, dateFilter];
}

class GetArticleUseCase
    implements UseCase<DataState<List<ArticleEntity>>, GetArticlesParams> {
  final ArticleRepository _articleRepository;

  GetArticleUseCase(this._articleRepository);

  @override
  Future<DataState<List<ArticleEntity>>> call({GetArticlesParams? params}) {
    return _articleRepository.getNewsArticles(
      page: params?.page ?? 1,
      dateFilter: params?.dateFilter,
    );
  }
}
