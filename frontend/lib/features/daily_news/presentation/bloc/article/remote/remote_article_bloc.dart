import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';

class RemoteArticlesBloc
    extends Bloc<RemoteArticlesEvent, RemoteArticlesState> {
  final GetArticleUseCase _getArticleUseCase;

  RemoteArticlesBloc(this._getArticleUseCase)
    : super(const RemoteArticlesState()) {
    on<GetArticles>(onGetArticles);
  }

  Future<void> onGetArticles(
    GetArticles event,
    Emitter<RemoteArticlesState> emit,
  ) async {
    if (event.loadMore && (state.isLoadingMore || state.hasReachedMax)) {
      return;
    }

    final selectedDate = event.clearDateFilter
        ? null
        : (event.selectedDate ?? state.selectedDate);
    final nextPage = event.loadMore ? state.currentPage + 1 : 1;

    emit(
      state.copyWith(
        articles: event.loadMore ? state.articles : const [],
        isLoading: !event.loadMore,
        isLoadingMore: event.loadMore,
        hasReachedMax: event.loadMore ? state.hasReachedMax : false,
        currentPage: event.loadMore ? state.currentPage : 0,
        selectedDate: selectedDate,
        clearSelectedDate: event.clearDateFilter,
        clearError: true,
      ),
    );

    final dataState = await _getArticleUseCase(
      params: GetArticlesParams(page: nextPage, dateFilter: selectedDate),
    );

    if (dataState is DataSuccess) {
      final incomingArticles = dataState.data ?? const <ArticleEntity>[];
      final articles = event.loadMore
          ? _mergeArticles(state.articles, incomingArticles)
          : incomingArticles;

      emit(
        state.copyWith(
          articles: articles,
          isLoading: false,
          isLoadingMore: false,
          hasReachedMax:
              incomingArticles.length < (nextPage * kDashboardPageSize),
          currentPage: nextPage,
          selectedDate: selectedDate,
          clearSelectedDate: event.clearDateFilter,
          clearError: true,
        ),
      );
      return;
    }

    if (dataState is DataFailed) {
      emit(
        state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: dataState.error,
          selectedDate: selectedDate,
          clearSelectedDate: event.clearDateFilter,
        ),
      );
    }
  }

  List<ArticleEntity> _mergeArticles(
    List<ArticleEntity> currentArticles,
    List<ArticleEntity> incomingArticles,
  ) {
    final articlesById = <String, ArticleEntity>{
      for (final article in currentArticles) _articleKey(article): article,
    };

    for (final article in incomingArticles) {
      articlesById[_articleKey(article)] = article;
    }

    return articlesById.values.toList();
  }

  String _articleKey(ArticleEntity article) {
    return article.firestoreId ?? article.id?.toString() ?? article.title ?? '';
  }
}
