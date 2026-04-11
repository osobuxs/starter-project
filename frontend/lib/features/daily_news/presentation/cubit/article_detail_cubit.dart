import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article_by_firestore_id.dart';

class ArticleDetailCubit extends Cubit<ArticleEntity?> {
  final GetArticleByFirestoreIdUseCase _getArticleByFirestoreId;

  ArticleDetailCubit(this._getArticleByFirestoreId) : super(null);

  Future<void> loadArticle(ArticleEntity? initialArticle) async {
    emit(initialArticle);

    final firestoreId = initialArticle?.firestoreId?.trim();
    if (firestoreId == null || firestoreId.isEmpty) {
      return;
    }

    final result = await _getArticleByFirestoreId(
      params: GetArticleByFirestoreIdParams(articleId: firestoreId),
    );

    if (result is DataSuccess<ArticleEntity> && result.data != null) {
      emit(result.data);
    }
  }
}
