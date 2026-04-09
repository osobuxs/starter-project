import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';

abstract class ArticleAuthoringRepository {
  Future<DataState<ArticleAuthoringEntity>> saveDraft(
    ArticleAuthoringEntity article,
  );

  Future<DataState<ArticleAuthoringEntity>> publishArticle(
    ArticleAuthoringEntity article,
  );

  Future<DataState<String>> uploadArticleImage(
    String authorId,
    String imagePath,
  );

  Future<DataState<ArticleAuthoringEntity>> getArticleById(String articleId);

  Future<DataState<List<ArticleAuthoringEntity>>> getArticlesByAuthorId(
    String authorId,
  );

  Future<DataState<ArticleAuthoringEntity>> updateArticleActiveState(
    ArticleAuthoringEntity article,
  );
}
