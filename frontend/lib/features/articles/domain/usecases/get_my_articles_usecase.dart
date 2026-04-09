import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class GetMyArticlesParams {
  final String authorId;

  const GetMyArticlesParams({required this.authorId});
}

class GetMyArticlesUseCase
    implements
        UseCase<DataState<List<ArticleAuthoringEntity>>, GetMyArticlesParams> {
  final ArticleAuthoringRepository _repository;

  GetMyArticlesUseCase(this._repository);

  @override
  Future<DataState<List<ArticleAuthoringEntity>>> call({
    GetMyArticlesParams? params,
  }) {
    return _repository.getArticlesByAuthorId(params!.authorId);
  }
}
