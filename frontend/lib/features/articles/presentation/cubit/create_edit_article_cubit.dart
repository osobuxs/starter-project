import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_orchestrator.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_validators.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';

class CreateEditArticleCubit extends Cubit<CreateEditArticleState> {
  static const Duration _timeout = Duration(seconds: 15);

  final CreateEditArticleOrchestrator _orchestrator;

  UserEntity? _currentUser;
  ArticleAuthorEntity? _currentAuthor;
  ArticleAuthoringEntity? _initialArticle;

  CreateEditArticleCubit({required CreateEditArticleOrchestrator orchestrator})
    : _orchestrator = orchestrator,
      super(const CreateEditArticleState());

  Future<void> initialize({String? articleId}) async {
    emit(
      state.copyWith(
        status: CreateEditArticleStatus.loading,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      _currentUser = await _orchestrator.getCurrentUser().timeout(_timeout);
      if (_currentUser == null) {
        emit(
          state.copyWith(
            status: CreateEditArticleStatus.failure,
            errorMessage:
                'Necesitás iniciar sesión para crear o editar una nota.',
            feedbackId: state.feedbackId + 1,
          ),
        );
        return;
      }

      _currentAuthor = await _orchestrator
          .buildAuthor(_currentUser!)
          .timeout(_timeout);

      if (articleId != null && articleId.isNotEmpty) {
        await _loadArticle(articleId);
        return;
      }

      _initialArticle = _orchestrator.buildEmptyArticle(_currentAuthor!);
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.ready,
          isEditMode: false,
          isPublished: false,
          articleId: null,
          title: '',
          subtitle: '',
          category: '',
          content: '',
          clearImageUrl: true,
          clearLocalImagePath: true,
          hasUnsavedChanges: false,
          clearTitleError: true,
          clearContentError: true,
          clearImageError: true,
          clearErrorMessage: true,
          clearSuccessMessage: true,
        ),
      );
    } on TimeoutException {
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage:
              'La pantalla tardó demasiado en cargar. Intentá nuevamente.',
          feedbackId: state.feedbackId + 1,
        ),
      );
    }
  }

  void onTitleChanged(String value) {
    emit(
      state.copyWith(
        title: value,
        clearTitleError: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(title: value),
      ),
    );
  }

  void onSubtitleChanged(String value) {
    emit(
      state.copyWith(
        subtitle: value,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(subtitle: value),
      ),
    );
  }

  void onCategoryChanged(String value) {
    emit(
      state.copyWith(
        category: value,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(category: value),
      ),
    );
  }

  void onContentChanged(String value) {
    emit(
      state.copyWith(
        content: value,
        clearContentError: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(content: value),
      ),
    );
  }

  Future<void> uploadSelectedImage(String imagePath) async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage:
              'No encontramos una sesión activa para subir la imagen.',
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isUploadingImage: true,
        localImagePath: imagePath,
        clearImageError: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final result = await _orchestrator
          .uploadImage(authorId: currentUser.id, imagePath: imagePath)
          .timeout(_timeout);

      if (result is DataFailed<String>) {
        emit(
          state.copyWith(
            isUploadingImage: false,
            imageError: 'No se pudo subir la imagen. Intentá nuevamente.',
            errorMessage: 'No se pudo subir la imagen seleccionada.',
            feedbackId: state.feedbackId + 1,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isUploadingImage: false,
          imageUrl: result.data,
          hasUnsavedChanges: _resolveUnsavedChanges(
            imageUrl: result.data,
            localImagePath: imagePath,
          ),
        ),
      );
    } on TimeoutException {
      emit(
        state.copyWith(
          isUploadingImage: false,
          imageError:
              'La carga de la imagen tardó demasiado. Intentá nuevamente.',
          errorMessage: 'La carga de la imagen tardó demasiado.',
          feedbackId: state.feedbackId + 1,
        ),
      );
    }
  }

  void removeSelectedImage() {
    emit(
      state.copyWith(
        clearImageUrl: true,
        clearLocalImagePath: true,
        clearImageError: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(
          imageUrl: '',
          localImagePath: '',
        ),
      ),
    );
  }

  Future<void> saveDraft() async {
    final validation = _orchestrator.validateDraft(state);
    if (!validation.isValid) {
      _emitValidationErrors(validation);
      return;
    }

    await _submit(saveAsDraft: true);
  }

  Future<void> publish() async {
    final validation = _orchestrator.validatePublish(state);
    if (!validation.isValid) {
      _emitValidationErrors(validation);
      return;
    }

    await _submit(saveAsDraft: false);
  }

  Future<void> _loadArticle(String articleId) async {
    final result = await _orchestrator.loadArticle(articleId).timeout(_timeout);

    if (result is DataFailed<ArticleAuthoringEntity> || result.data == null) {
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage: 'No pudimos cargar la nota para editarla.',
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    final article = result.data!;
    if (_currentUser?.id != article.author.id) {
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage: 'No tenés permisos para editar esta nota.',
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    _initialArticle = article;

    emit(
      state.copyWith(
        status: CreateEditArticleStatus.ready,
        isEditMode: true,
        isPublished: article.isPublished,
        articleId: article.firestoreId,
        title: article.title,
        subtitle: article.subtitle ?? '',
        category: article.category,
        content: article.content,
        imageUrl: article.imageUrl,
        clearLocalImagePath: true,
        hasUnsavedChanges: false,
        clearTitleError: true,
        clearContentError: true,
        clearImageError: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<void> _submit({required bool saveAsDraft}) async {
    final author = _currentAuthor;
    if (author == null) {
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage: 'No se pudo resolver el autor de la nota.',
          feedbackId: state.feedbackId + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: CreateEditArticleStatus.submitting,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final article = _buildArticleFromState(
      author: author,
      publish: !saveAsDraft,
    );

    try {
      final result = saveAsDraft
          ? await _orchestrator.saveDraft(article).timeout(_timeout)
          : await _orchestrator.publish(article).timeout(_timeout);

      if (result is DataFailed<ArticleAuthoringEntity> || result.data == null) {
        emit(
          state.copyWith(
            status: CreateEditArticleStatus.failure,
            errorMessage: saveAsDraft
                ? 'No se pudo guardar el borrador. Intentá nuevamente.'
                : 'No se pudo publicar la nota. Intentá nuevamente.',
            feedbackId: state.feedbackId + 1,
          ),
        );
        return;
      }

      final persistedArticle = result.data!;
      _initialArticle = persistedArticle;

      emit(
        state.copyWith(
          status: CreateEditArticleStatus.ready,
          isEditMode: true,
          isPublished: persistedArticle.isPublished,
          articleId: persistedArticle.firestoreId,
          title: persistedArticle.title,
          subtitle: persistedArticle.subtitle ?? '',
          category: persistedArticle.category,
          content: persistedArticle.content,
          imageUrl: persistedArticle.imageUrl,
          hasUnsavedChanges: false,
          successMessage: saveAsDraft
              ? 'Borrador guardado con éxito.'
              : 'Nota publicada con éxito.',
          feedbackId: state.feedbackId + 1,
        ),
      );
    } on TimeoutException {
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage: saveAsDraft
              ? 'Guardar el borrador tardó demasiado. Intentá nuevamente.'
              : 'La publicación tardó demasiado. Intentá nuevamente.',
          feedbackId: state.feedbackId + 1,
        ),
      );
    }
  }

  ArticleAuthoringEntity _buildArticleFromState({
    required ArticleAuthorEntity author,
    required bool publish,
  }) {
    return _orchestrator.buildArticleFromState(
      state: state,
      author: author,
      baseline: _initialArticle,
      publish: publish,
    );
  }

  bool _resolveUnsavedChanges({
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    String? localImagePath,
  }) {
    return _orchestrator.hasUnsavedChanges(
      state: state,
      baseline: _initialArticle,
      title: title,
      subtitle: subtitle,
      category: category,
      content: content,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
    );
  }

  void _emitValidationErrors(CreateEditArticleValidation validation) {
    emit(
      state.copyWith(
        status: CreateEditArticleStatus.ready,
        titleError: validation.titleError,
        contentError: validation.contentError,
        imageError: validation.imageError,
        errorMessage: 'Revisá los campos obligatorios antes de continuar.',
        feedbackId: state.feedbackId + 1,
      ),
    );
  }
}
