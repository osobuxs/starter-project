// Run mock generation before running tests:
// dart run build_runner build --delete-conflicting-outputs
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/article_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

import 'article_repository_impl_test.mocks.dart';

@GenerateMocks([ArticleFirestoreDataSource, AppDatabase])
void main() {
  late MockArticleFirestoreDataSource mockFirestoreDataSource;
  late MockAppDatabase mockDatabase;
  late ArticleRepositoryImpl repository;

  setUp(() {
    mockFirestoreDataSource = MockArticleFirestoreDataSource();
    mockDatabase = MockAppDatabase();
    repository = ArticleRepositoryImpl(mockFirestoreDataSource, mockDatabase);
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
}
