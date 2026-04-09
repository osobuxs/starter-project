import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';

class UploadArticleImageParams {
  final String authorId;
  final String imagePath;

  const UploadArticleImageParams({
    required this.authorId,
    required this.imagePath,
  });
}

class UploadArticleImageUseCase
    implements UseCase<DataState<String>, UploadArticleImageParams> {
  final ArticleAuthoringRepository _repository;

  UploadArticleImageUseCase(this._repository);

  @override
  Future<DataState<String>> call({UploadArticleImageParams? params}) {
    return _repository.uploadArticleImage(params!.authorId, params.imagePath);
  }
}
