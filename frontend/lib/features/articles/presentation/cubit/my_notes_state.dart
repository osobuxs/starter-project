import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';

enum MyNotesStatus { initial, loading, ready, failure, actionInProgress }

class MyNotesState extends Equatable {
  final MyNotesStatus status;
  final List<ArticleAuthoringEntity> articles;
  final String? errorMessage;
  final String? successMessage;
  final int feedbackId;
  final String? actionArticleId;

  const MyNotesState({
    this.status = MyNotesStatus.initial,
    this.articles = const [],
    this.errorMessage,
    this.successMessage,
    this.feedbackId = 0,
    this.actionArticleId,
  });

  bool isBusy(String? articleId) =>
      status == MyNotesStatus.actionInProgress && actionArticleId == articleId;

  MyNotesState copyWith({
    MyNotesStatus? status,
    List<ArticleAuthoringEntity>? articles,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    int? feedbackId,
    String? actionArticleId,
    bool clearActionArticleId = false,
  }) {
    return MyNotesState(
      status: status ?? this.status,
      articles: articles ?? this.articles,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      feedbackId: feedbackId ?? this.feedbackId,
      actionArticleId: clearActionArticleId
          ? null
          : (actionArticleId ?? this.actionArticleId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    articles,
    errorMessage,
    successMessage,
    feedbackId,
    actionArticleId,
  ];
}
