import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article_by_firestore_id.dart';

class ArticleDetailCubit extends Cubit<ArticleDetailState> {
  final GetArticleByFirestoreIdUseCase _getArticleByFirestoreId;

  ArticleDetailCubit(this._getArticleByFirestoreId)
    : super(const ArticleDetailState());

  Future<void> loadArticle(ArticleEntity? initialArticle) async {
    final firestoreId = initialArticle?.firestoreId?.trim();
    final shouldRefresh = firestoreId != null && firestoreId.isNotEmpty;

    emit(
      ArticleDetailState(article: initialArticle, isRefreshing: shouldRefresh),
    );

    if (firestoreId == null || firestoreId.isEmpty) {
      return;
    }

    final result = await _getArticleByFirestoreId(
      params: GetArticleByFirestoreIdParams(articleId: firestoreId),
    );

    if (result is DataSuccess<ArticleEntity> && result.data != null) {
      emit(ArticleDetailState(article: result.data));
      return;
    }

    emit(state.copyWith(isRefreshing: false));
  }
}

class ArticleDetailState extends Equatable {
  final ArticleEntity? article;
  final bool isRefreshing;

  const ArticleDetailState({this.article, this.isRefreshing = false});

  ArticleDetailState copyWith({ArticleEntity? article, bool? isRefreshing}) {
    return ArticleDetailState(
      article: article ?? this.article,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [article, isRefreshing];
}
