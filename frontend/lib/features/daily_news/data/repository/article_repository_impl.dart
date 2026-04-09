import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/article_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleFirestoreDataSource _articleFirestoreDataSource;
  final AppDatabase _appDatabase;

  ArticleRepositoryImpl(this._articleFirestoreDataSource, this._appDatabase);

  @override
  Future<DataState<List<ArticleEntity>>> getNewsArticles({
    required int page,
    DateTime? dateFilter,
  }) async {
    try {
      final articles = await _articleFirestoreDataSource.getPublishedArticles(
        page: page,
        dateFilter: dateFilter,
      );

      return DataSuccess(
        articles.map((article) => article.toEntity()).toList(),
      );
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<List<ArticleEntity>> getSavedArticles() async {
    return _appDatabase.articleDAO.getArticles();
  }

  @override
  Future<void> removeArticle(ArticleEntity article) {
    return _appDatabase.articleDAO.deleteArticle(
      ArticleModel.fromEntity(article),
    );
  }

  @override
  Future<void> saveArticle(ArticleEntity article) {
    return _appDatabase.articleDAO.insertArticle(
      ArticleModel.fromEntity(article),
    );
  }
}
