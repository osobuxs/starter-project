import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class SaveArticleDraftParams {
  final ArticleAuthoringEntity article;

  const SaveArticleDraftParams({required this.article});
}

class SaveArticleDraftUseCase
    implements
        UseCase<DataState<ArticleAuthoringEntity>, SaveArticleDraftParams> {
  final ArticleAuthoringRepository _repository;

  SaveArticleDraftUseCase(this._repository);

  @override
  Future<DataState<ArticleAuthoringEntity>> call({
    SaveArticleDraftParams? params,
  }) {
    return _repository.saveDraft(params!.article);
  }
}
