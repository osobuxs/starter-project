import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/article_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/favorite_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/paginated_articles_model.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles_entity.dart';

class _StubArticleFirestoreDataSource implements ArticleFirestoreDataSource {
  List<ArticleModel> articles;
  Object? error;

  _StubArticleFirestoreDataSource({this.articles = const [], this.error});

  @override
  Future<ArticleModel?> getArticleByFirestoreId(String articleId) async {
    if (error != null) throw Exception(error.toString());
    return articles.cast<ArticleModel?>().firstWhere(
      (article) => article?.firestoreId == articleId,
      orElse: () => null,
    );
  }

  @override
  Future<PaginatedArticlesModel> getPublishedArticles({
    ArticlePaginationCursor? after,
    DateTime? dateFilter,
  }) async {
    if (error != null) throw Exception(error.toString());
    return PaginatedArticlesModel(
      articles: articles,
      nextCursor: null,
      hasReachedMax: true,
    );
  }
}

class _StubFavoriteFirestoreDataSource implements FavoriteFirestoreDataSource {
  List<ArticleModel> favorites;
  Object? error;
  ArticleModel? lastSaved;
  String? lastRemovedId;

  _StubFavoriteFirestoreDataSource({this.favorites = const [], this.error});

  @override
  Future<List<ArticleModel>> getFavoriteArticles() async {
    if (error != null) throw Exception(error.toString());
    return favorites;
  }

  @override
  Future<void> removeFavoriteArticle(String articleId) async {
    if (error != null) throw Exception(error.toString());
    lastRemovedId = articleId;
  }

  @override
  Future<void> saveFavoriteArticle(ArticleModel article) async {
    if (error != null) throw Exception(error.toString());
    lastSaved = article;
  }
}

void main() {
  late _StubArticleFirestoreDataSource firestoreDataSource;
  late _StubFavoriteFirestoreDataSource favoriteDataSource;
  late ArticleRepositoryImpl repository;

  setUp(() {
    firestoreDataSource = _StubArticleFirestoreDataSource();
    favoriteDataSource = _StubFavoriteFirestoreDataSource();
    repository = ArticleRepositoryImpl(firestoreDataSource, favoriteDataSource);
  });

  group('getNewsArticles', () {
    final tArticles = [
      const ArticleModel(
        author: 'Author',
        title: 'Title',
        description: 'Desc',
        url: 'https://example.com',
        urlToImage: 'https://example.com/img.jpg',
        publishedAt: '2024-01-01',
        content: 'Content',
      ),
    ];

    test('returns DataSuccess with paginated articles', () async {
      firestoreDataSource.articles = tArticles;

      final result = await repository.getNewsArticles();

      expect(result, isA<DataSuccess<PaginatedArticlesEntity>>());
      expect(result.data?.articles, isNotEmpty);
    });

    test('returns DataFailed when data source throws', () async {
      firestoreDataSource.error = 'firestore failed';

      final result = await repository.getNewsArticles();

      expect(result, isA<DataFailed<PaginatedArticlesEntity>>());
    });
  });

  group('favorites', () {
    const tArticle = ArticleModel(
      firestoreId: 'article-1',
      title: 'Title',
      description: 'Desc',
      url: 'https://example.com',
      urlToImage: 'https://example.com/img.jpg',
      publishedAt: '2024-01-01',
      content: 'Content',
    );

    test(
      'getSavedArticles returns DataSuccess with favorite entities',
      () async {
        favoriteDataSource.favorites = const [tArticle];

        final result = await repository.getSavedArticles();

        expect(result, isA<DataSuccess<List<ArticleEntity>>>());
        expect(result.data, hasLength(1));
        expect(result.data?.first.firestoreId, 'article-1');
      },
    );

    test(
      'saveArticle persists favorite through firestore data source',
      () async {
        final result = await repository.saveArticle(tArticle);

        expect(result, isA<DataSuccess<void>>());
        expect(favoriteDataSource.lastSaved?.firestoreId, 'article-1');
      },
    );

    test('removeArticle deletes favorite by firestore id', () async {
      final result = await repository.removeArticle(tArticle);

      expect(result, isA<DataSuccess<void>>());
      expect(favoriteDataSource.lastRemovedId, 'article-1');
    });
  });
}
