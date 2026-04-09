// Run mock generation before running tests:
// dart run build_runner build --delete-conflicting-outputs
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:retrofit/retrofit.dart';

import 'article_repository_impl_test.mocks.dart';

@GenerateMocks([NewsApiService, AppDatabase])
void main() {
  late MockNewsApiService mockApiService;
  late MockAppDatabase mockDatabase;
  late ArticleRepositoryImpl repository;

  setUp(() {
    mockApiService = MockNewsApiService();
    mockDatabase = MockAppDatabase();
    repository = ArticleRepositoryImpl(mockApiService, mockDatabase);
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

    test('returns DataSuccess with List<ArticleEntity> on HTTP 200', () async {
      final fakeResponse = Response<List<ArticleModel>>(
        data: tArticles,
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        statusMessage: 'OK',
      );
      when(mockApiService.getNewsArticles(
        apiKey: anyNamed('apiKey'),
        country: anyNamed('country'),
        category: anyNamed('category'),
      )).thenAnswer((_) async => HttpResponse(tArticles, fakeResponse));

      final result = await repository.getNewsArticles();

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data, isNotEmpty);
    });

    test('returns DataFailed on non-200 status code', () async {
      final fakeResponse = Response<List<ArticleModel>>(
        data: null,
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Internal Server Error',
      );
      when(mockApiService.getNewsArticles(
        apiKey: anyNamed('apiKey'),
        country: anyNamed('country'),
        category: anyNamed('category'),
      )).thenAnswer((_) async => HttpResponse([], fakeResponse));

      final result = await repository.getNewsArticles();

      expect(result, isA<DataFailed<List<ArticleEntity>>>());
    });

    test('returns DataFailed when DioException is thrown', () async {
      when(mockApiService.getNewsArticles(
        apiKey: anyNamed('apiKey'),
        country: anyNamed('country'),
        category: anyNamed('category'),
      )).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      final result = await repository.getNewsArticles();

      expect(result, isA<DataFailed<List<ArticleEntity>>>());
    });
  });
}
