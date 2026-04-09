import 'package:equatable/equatable.dart';
import '../../../../domain/entities/article.dart';

class RemoteArticlesState extends Equatable {
  final List<ArticleEntity> articles;
  final Exception? error;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;
  final DateTime? selectedDate;

  const RemoteArticlesState({
    this.articles = const [],
    this.error,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.selectedDate,
  });

  RemoteArticlesState copyWith({
    List<ArticleEntity>? articles,
    Exception? error,
    bool clearError = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) {
    return RemoteArticlesState(
      articles: articles ?? this.articles,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      selectedDate: clearSelectedDate
          ? null
          : (selectedDate ?? this.selectedDate),
    );
  }

  @override
  List<Object?> get props => [
    articles,
    error,
    isLoading,
    isLoadingMore,
    hasReachedMax,
    currentPage,
    selectedDate,
  ];
}
