import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_my_articles_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/update_article_active_state_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';

class MyNotesCubit extends Cubit<MyNotesState> {
  static const Duration _timeout = Duration(seconds: 15);

  final GetCurrentUserUseCase _getCurrentUser;
  final GetMyArticlesUseCase _getMyArticles;
  final PublishArticleUseCase _publishArticle;
  final UpdateArticleActiveStateUseCase _updateArticleActiveState;

  UserEntity? _currentUser;

  MyNotesCubit({
    required GetCurrentUserUseCase getCurrentUser,
    required GetMyArticlesUseCase getMyArticles,
    required PublishArticleUseCase publishArticle,
    required UpdateArticleActiveStateUseCase updateArticleActiveState,
  }) : _getCurrentUser = getCurrentUser,
       _getMyArticles = getMyArticles,
       _publishArticle = publishArticle,
       _updateArticleActiveState = updateArticleActiveState,
       super(const MyNotesState());

  Future<void> initialize() async {
    emit(
      state.copyWith(
        status: MyNotesStatus.loading,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearActionArticleId: true,
      ),
    );

    try {
      _currentUser = await _getCurrentUser().timeout(_timeout);
      final currentUser = _currentUser;
      if (currentUser == null) {
        emit(
          state.copyWith(
            status: MyNotesStatus.failure,
            errorMessage: 'Necesitás iniciar sesión para ver tus notas.',
            feedbackId: state.feedbackId + 1,
          ),
        );
        return;
      }

      await _loadArticles(currentUser.id);
    } on TimeoutException {
      emit(
        state.copyWith(
          status: MyNotesStatus.failure,
          errorMessage:
              'La carga de tus notas tardó demasiado. Intentá nuevamente.',
          feedbackId: state.feedbackId + 1,
        ),
      );
    }
  }

  Future<void> refresh() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      await initialize();
      return;
    }

    await _loadArticles(currentUser.id);
  }

  Future<void> publish(ArticleAuthoringEntity article) async {
    final publishValidationMessage = _validatePublishableArticle(article);
    if (publishValidationMessage != null) {
      emit(
        state.copyWith(
          status: MyNotesStatus.ready,
          errorMessage: publishValidationMessage,
          feedbackId: state.feedbackId + 1,
          clearActionArticleId: true,
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final articleToPublish = article.copyWith(
      isPublished: true,
      isActive: true,
      updatedAt: now,
      publishedAt: article.publishedAt ?? now,
    );

    await _runArticleAction(
      article: article,
      operation: () => _publishArticle(
        params: PublishArticleParams(article: articleToPublish),
      ).timeout(_timeout),
      successMessage: 'La nota se publicó con éxito.',
    );
  }

  Future<void> setActiveState(
    ArticleAuthoringEntity article, {
    required bool isActive,
  }) async {
    final updatedArticle = article.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    await _runArticleAction(
      article: article,
      operation: () => _updateArticleActiveState(
        params: UpdateArticleActiveStateParams(article: updatedArticle),
      ).timeout(_timeout),
      successMessage: isActive ? 'La nota se reactivó.' : 'La nota se archivó.',
    );
  }

  String? _validatePublishableArticle(ArticleAuthoringEntity article) {
    if (article.title.trim().isEmpty ||
        article.content.trim().isEmpty ||
        article.imageUrl == null ||
        article.imageUrl!.trim().isEmpty) {
      return 'No pudimos publicar la nota. Completá título, contenido e imagen desde el editor y volvé a intentarlo.';
    }

    return null;
  }

  Future<void> _loadArticles(String authorId) async {
    final result = await _getMyArticles(
      params: GetMyArticlesParams(authorId: authorId),
    ).timeout(_timeout);

    if (result is DataFailed<List<ArticleAuthoringEntity>>) {
      emit(
        state.copyWith(
          status: MyNotesStatus.failure,
          errorMessage: 'No pudimos cargar tus notas. Intentá nuevamente.',
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: MyNotesStatus.ready,
        articles: result.data ?? const [],
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearActionArticleId: true,
      ),
    );
  }

  Future<void> _runArticleAction({
    required ArticleAuthoringEntity article,
    required Future<DataState<ArticleAuthoringEntity>> Function() operation,
    required String successMessage,
  }) async {
    emit(
      state.copyWith(
        status: MyNotesStatus.actionInProgress,
        actionArticleId: article.firestoreId,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final result = await operation();
      if (result is DataFailed<ArticleAuthoringEntity> || result.data == null) {
        emit(
          state.copyWith(
            status: MyNotesStatus.ready,
            errorMessage:
                'No pudimos actualizar esta nota. Intentá nuevamente.',
            feedbackId: state.feedbackId + 1,
            clearActionArticleId: true,
          ),
        );
        return;
      }

      final updatedArticles = state.articles
          .map(
            (currentArticle) =>
                currentArticle.firestoreId == result.data!.firestoreId
                ? result.data!
                : currentArticle,
          )
          .toList();

      emit(
        state.copyWith(
          status: MyNotesStatus.ready,
          articles: updatedArticles,
          successMessage: successMessage,
          feedbackId: state.feedbackId + 1,
          clearActionArticleId: true,
        ),
      );
    } on TimeoutException {
      emit(
        state.copyWith(
          status: MyNotesStatus.ready,
          errorMessage: 'La operación tardó demasiado. Intentá nuevamente.',
          feedbackId: state.feedbackId + 1,
          clearActionArticleId: true,
        ),
      );
    }
  }
}
