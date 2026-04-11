import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles_entity.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';

class _StubGetArticleUseCase implements GetArticleUseCase {
  Future<DataState<PaginatedArticlesEntity>> Function({
    GetArticlesParams? params,
  })
  handler;

  _StubGetArticleUseCase({required this.handler});

  @override
  Future<DataState<PaginatedArticlesEntity>> call({GetArticlesParams? params}) {
    return handler(params: params);
  }
}

void main() {
  const firstCursor = ArticlePaginationCursor(
    createdAt: DateTime(2026, 1, 1),
    firestoreId: 'article-1',
  );
  const secondCursor = ArticlePaginationCursor(
    createdAt: DateTime(2026, 1, 2),
    firestoreId: 'article-2',
  );

  const firstArticle = ArticleEntity(
    firestoreId: 'article-1',
    title: 'First article',
    content: 'First content',
  );
  const secondArticle = ArticleEntity(
    firestoreId: 'article-2',
    title: 'Second article',
    content: 'Second content',
  );

  group('RemoteArticlesBloc cursor pagination', () {
    blocTest<RemoteArticlesBloc, RemoteArticlesState>(
      'loads first page and stores next cursor',
      build: () {
        final useCase = _StubGetArticleUseCase(
          handler: ({params}) async {
            expect(params?.after, isNull);
            return const DataSuccess(
              PaginatedArticlesEntity(
                articles: [firstArticle],
                nextCursor: firstCursor,
                hasReachedMax: false,
              ),
            );
          },
        );
        return RemoteArticlesBloc(useCase);
      },
      act: (bloc) => bloc.add(const GetArticles()),
      expect: () => [
        isA<RemoteArticlesState>()
            .having((state) => state.articles.length, 'articles length', 1)
            .having((state) => state.currentPage, 'currentPage', 1)
            .having((state) => state.nextCursor, 'nextCursor', firstCursor)
            .having((state) => state.hasReachedMax, 'hasReachedMax', false),
      ],
    );

    blocTest<RemoteArticlesBloc, RemoteArticlesState>(
      'load more uses cursor and appends articles',
      build: () {
        final useCase = _StubGetArticleUseCase(
          handler: ({params}) async {
            expect(params?.after, firstCursor);
            return const DataSuccess(
              PaginatedArticlesEntity(
                articles: [secondArticle],
                nextCursor: secondCursor,
                hasReachedMax: true,
              ),
            );
          },
        );
        return RemoteArticlesBloc(useCase);
      },
      seed: () => const RemoteArticlesState(
        articles: [firstArticle],
        isLoading: false,
        currentPage: 1,
        nextCursor: firstCursor,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(const GetArticles(loadMore: true)),
      expect: () => [
        isA<RemoteArticlesState>()
            .having((state) => state.isLoadingMore, 'isLoadingMore', true)
            .having((state) => state.articles.length, 'articles length', 1),
        isA<RemoteArticlesState>()
            .having((state) => state.articles.length, 'articles length', 2)
            .having((state) => state.currentPage, 'currentPage', 2)
            .having((state) => state.nextCursor, 'nextCursor', secondCursor)
            .having((state) => state.hasReachedMax, 'hasReachedMax', true)
            .having((state) => state.isLoadingMore, 'isLoadingMore', false),
      ],
    );
  });
}
