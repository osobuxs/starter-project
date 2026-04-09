import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class UpdateArticleActiveStateParams {
  final ArticleAuthoringEntity article;

  const UpdateArticleActiveStateParams({required this.article});
}

class UpdateArticleActiveStateUseCase
    implements
        UseCase<
          DataState<ArticleAuthoringEntity>,
          UpdateArticleActiveStateParams
        > {
  final ArticleAuthoringRepository _repository;

  UpdateArticleActiveStateUseCase(this._repository);

  @override
  Future<DataState<ArticleAuthoringEntity>> call({
    UpdateArticleActiveStateParams? params,
  }) {
    return _repository.updateArticleActiveState(params!.article);
  }
}
