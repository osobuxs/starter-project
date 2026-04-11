import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class GetArticleByFirestoreIdParams {
  final String articleId;

  const GetArticleByFirestoreIdParams({required this.articleId});
}

class GetArticleByFirestoreIdUseCase
    implements
        UseCase<DataState<ArticleEntity>, GetArticleByFirestoreIdParams> {
  final ArticleRepository _articleRepository;

  GetArticleByFirestoreIdUseCase(this._articleRepository);

  @override
  Future<DataState<ArticleEntity>> call({
    GetArticleByFirestoreIdParams? params,
  }) {
    return _articleRepository.getArticleByFirestoreId(params!.articleId);
  }
}
