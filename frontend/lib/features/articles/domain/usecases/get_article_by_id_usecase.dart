import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class GetArticleByIdParams {
  final String articleId;

  const GetArticleByIdParams({required this.articleId});
}

class GetArticleByIdUseCase
    implements
        UseCase<DataState<ArticleAuthoringEntity>, GetArticleByIdParams> {
  final ArticleAuthoringRepository _repository;

  GetArticleByIdUseCase(this._repository);

  @override
  Future<DataState<ArticleAuthoringEntity>> call({
    GetArticleByIdParams? params,
  }) {
    return _repository.getArticleById(params!.articleId);
  }
}
