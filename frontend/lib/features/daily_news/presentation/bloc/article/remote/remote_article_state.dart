import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';
import '../../../../domain/entities/article.dart';

class RemoteArticlesState extends Equatable {
  final List<ArticleEntity> articles;
  final Exception? error;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;
  final DateTime? selectedDate;
  final ArticlePaginationCursor? nextCursor;

  const RemoteArticlesState({
    this.articles = const [],
    this.error,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.selectedDate,
    this.nextCursor,
  });

  RemoteArticlesState copyWith({
    List<ArticleEntity>? articles,
    Exception? error,
    bool clearError = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    ArticlePaginationCursor? nextCursor,
    bool clearNextCursor = false,
  }) {
    return RemoteArticlesState(
      articles: articles ?? this.articles,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      selectedDate: clearSelectedDate
          ? null
          : (selectedDate ?? this.selectedDate),
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    );
  }

  @override
  List<Object?> get props => [
    articles,
    error,
    isLoading,
    isRefreshing,
    isLoadingMore,
    hasReachedMax,
    currentPage,
    selectedDate,
    nextCursor,
  ];
}
