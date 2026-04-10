import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/local/local_article_state.dart';

import '../../../../domain/entities/article.dart';
import '../../../../domain/usecases/get_saved_article.dart';
import '../../../../domain/usecases/remove_article.dart';
import '../../../../domain/usecases/save_article.dart';

class LocalArticleBloc extends Bloc<LocalArticlesEvent, LocalArticlesState> {
  final GetSavedArticleUseCase _getSavedArticleUseCase;
  final SaveArticleUseCase _saveArticleUseCase;
  final RemoveArticleUseCase _removeArticleUseCase;

  LocalArticleBloc(
    this._getSavedArticleUseCase,
    this._saveArticleUseCase,
    this._removeArticleUseCase,
  ) : super(const LocalArticlesLoading()) {
    on<GetSavedArticles>(onGetSavedArticles);
    on<RemoveArticle>(onRemoveArticle);
    on<SaveArticle>(onSaveArticle);
  }

  Future<void> onGetSavedArticles(
    GetSavedArticles event,
    Emitter<LocalArticlesState> emit,
  ) async {
    emit(const LocalArticlesLoading());
    final result = await _getSavedArticleUseCase();
    emit(_mapArticlesResult(result));
  }

  Future<void> onRemoveArticle(
    RemoveArticle removeArticle,
    Emitter<LocalArticlesState> emit,
  ) async {
    final actionResult = await _removeArticleUseCase(
      params: removeArticle.article,
    );
    if (actionResult is DataFailed<void>) {
      emit(
        LocalArticlesError(
          _resolveErrorMessage(
            actionResult.error,
            fallback: 'No pudimos quitar este favorito.',
          ),
          articles: state.articles,
        ),
      );
      return;
    }

    final refreshedResult = await _getSavedArticleUseCase();
    emit(
      _mapArticlesResult(
        refreshedResult,
        successMessage: 'Se quitó de favoritos.',
      ),
    );
  }

  Future<void> onSaveArticle(
    SaveArticle saveArticle,
    Emitter<LocalArticlesState> emit,
  ) async {
    final actionResult = await _saveArticleUseCase(params: saveArticle.article);
    if (actionResult is DataFailed<void>) {
      emit(
        LocalArticlesError(
          _resolveErrorMessage(
            actionResult.error,
            fallback: 'No pudimos guardar este favorito.',
          ),
          articles: state.articles,
        ),
      );
      return;
    }

    final refreshedResult = await _getSavedArticleUseCase();
    emit(
      _mapArticlesResult(
        refreshedResult,
        successMessage: 'Se agregó a favoritos.',
      ),
    );
  }

  LocalArticlesState _mapArticlesResult(
    DataState<List<ArticleEntity>> result, {
    String? successMessage,
  }) {
    if (result is DataSuccess<List<ArticleEntity>>) {
      return LocalArticlesDone(
        result.data ?? const [],
        message: successMessage,
      );
    }

    return LocalArticlesError(
      _resolveErrorMessage(
        result.error,
        fallback: 'No pudimos cargar tus favoritos.',
      ),
      articles: state.articles,
    );
  }

  String _resolveErrorMessage(Exception? error, {required String fallback}) {
    final rawMessage = error?.toString().trim();
    if (rawMessage == null || rawMessage.isEmpty) {
      return fallback;
    }

    return rawMessage.startsWith('Exception: ')
        ? rawMessage.replaceFirst('Exception: ', '')
        : rawMessage;
  }
}
