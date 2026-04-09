import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class PublishArticleParams {
  final ArticleAuthoringEntity article;

  const PublishArticleParams({required this.article});
}

class PublishArticleUseCase
    implements
        UseCase<DataState<ArticleAuthoringEntity>, PublishArticleParams> {
  final ArticleAuthoringRepository _repository;

  PublishArticleUseCase(this._repository);

  @override
  Future<DataState<ArticleAuthoringEntity>> call({
    PublishArticleParams? params,
  }) {
    return _repository.publishArticle(params!.article);
  }
}
