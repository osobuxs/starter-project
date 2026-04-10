import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/article_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/favorite_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

class MockArticleFirestoreDataSource extends Mock
    implements ArticleFirestoreDataSource {}

class MockFavoriteFirestoreDataSource extends Mock
    implements FavoriteFirestoreDataSource {}

void main() {
  late MockArticleFirestoreDataSource mockFirestoreDataSource;
  late MockFavoriteFirestoreDataSource mockFavoriteFirestoreDataSource;
  late ArticleRepositoryImpl repository;

  setUp(() {
    mockFirestoreDataSource = MockArticleFirestoreDataSource();
    mockFavoriteFirestoreDataSource = MockFavoriteFirestoreDataSource();
    repository = ArticleRepositoryImpl(
      mockFirestoreDataSource,
      mockFavoriteFirestoreDataSource,
    );
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

    test('returns DataSuccess with List<ArticleEntity>', () async {
      when(
        mockFirestoreDataSource.getPublishedArticles(
          page: anyNamed('page'),
          dateFilter: anyNamed('dateFilter'),
        ),
      ).thenAnswer((_) async => tArticles);

      final result = await repository.getNewsArticles(page: 1);

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data, isNotEmpty);
    });

    test('returns DataFailed when data source throws', () async {
      when(
        mockFirestoreDataSource.getPublishedArticles(
          page: anyNamed('page'),
          dateFilter: anyNamed('dateFilter'),
        ),
      ).thenThrow(Exception('firestore failed'));

      final result = await repository.getNewsArticles(page: 1);

      expect(result, isA<DataFailed<List<ArticleEntity>>>());
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
        when(
          mockFavoriteFirestoreDataSource.getFavoriteArticles(),
        ).thenAnswer((_) async => const [tArticle]);

        final result = await repository.getSavedArticles();

        expect(result, isA<DataSuccess<List<ArticleEntity>>>());
        expect(result.data, hasLength(1));
        expect(result.data?.first.firestoreId, 'article-1');
      },
    );

    test(
      'saveArticle persists favorite through firestore data source',
      () async {
        when(
          mockFavoriteFirestoreDataSource.saveFavoriteArticle(any),
        ).thenAnswer((_) async {});

        final result = await repository.saveArticle(tArticle);

        expect(result, isA<DataSuccess<void>>());
        verify(
          mockFavoriteFirestoreDataSource.saveFavoriteArticle(any),
        ).called(1);
      },
    );

    test('removeArticle deletes favorite by firestore id', () async {
      when(
        mockFavoriteFirestoreDataSource.removeFavoriteArticle('article-1'),
      ).thenAnswer((_) async {});

      final result = await repository.removeArticle(tArticle);

      expect(result, isA<DataSuccess<void>>());
      verify(
        mockFavoriteFirestoreDataSource.removeFavoriteArticle('article-1'),
      ).called(1);
    });
  });
}
