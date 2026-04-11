import 'dart:async';

import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_orchestrator.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_validators.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';

typedef StateReader = CreateEditArticleState Function();
typedef StateWriter = void Function(CreateEditArticleState state);

class CreateEditArticleStateHandlers {
  final CreateEditArticleOrchestrator orchestrator;
  final StateReader read;
  final StateWriter write;
  final Duration timeout;

  UserEntity? _currentUser;
  ArticleAuthorEntity? _currentAuthor;
  ArticleAuthoringEntity? _initialArticle;

  CreateEditArticleStateHandlers({
    required this.orchestrator,
    required this.read,
    required this.write,
    required this.timeout,
  });

  Future<void> initialize({String? articleId}) async {
    _emit(
      _state.copyWith(
        status: CreateEditArticleStatus.loading,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      _currentUser = await orchestrator.getCurrentUser().timeout(timeout);
      if (_currentUser == null) {
        _emitFailure('Necesitás iniciar sesión para crear o editar una nota.');
        return;
      }

      _currentAuthor = await orchestrator
          .buildAuthor(_currentUser!)
          .timeout(timeout);

      if (articleId != null && articleId.isNotEmpty) {
        await _loadArticle(articleId);
        return;
      }

      _initialArticle = orchestrator.buildEmptyArticle(_currentAuthor!);
      _emit(
        _state.copyWith(
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
      _emitFailure(
        'La pantalla tardó demasiado en cargar. Intentá nuevamente.',
      );
    }
  }

  void onTitleChanged(String value) {
    _emit(
      _state.copyWith(
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
    _emit(
      _state.copyWith(
        subtitle: value,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(subtitle: value),
      ),
    );
  }

  void onCategoryChanged(String value) {
    _emit(
      _state.copyWith(
        category: value,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        status: CreateEditArticleStatus.ready,
        hasUnsavedChanges: _resolveUnsavedChanges(category: value),
      ),
    );
  }

  void onContentChanged(String value) {
    _emit(
      _state.copyWith(
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
      _emitFailure('No encontramos una sesión activa para subir la imagen.');
      return;
    }

    _emit(
      _state.copyWith(
        isUploadingImage: true,
        localImagePath: imagePath,
        clearImageError: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final result = await orchestrator
          .uploadImage(authorId: currentUser.id, imagePath: imagePath)
          .timeout(timeout);

      if (result is DataFailed<String>) {
        _emit(
          _state.copyWith(
            isUploadingImage: false,
            imageError: 'No se pudo subir la imagen. Intentá nuevamente.',
            errorMessage: 'No se pudo subir la imagen seleccionada.',
            feedbackId: _state.feedbackId + 1,
          ),
        );
        return;
      }

      _emit(
        _state.copyWith(
          isUploadingImage: false,
          imageUrl: result.data,
          hasUnsavedChanges: _resolveUnsavedChanges(
            imageUrl: result.data,
            localImagePath: imagePath,
          ),
        ),
      );
    } on TimeoutException {
      _emit(
        _state.copyWith(
          isUploadingImage: false,
          imageError:
              'La carga de la imagen tardó demasiado. Intentá nuevamente.',
          errorMessage: 'La carga de la imagen tardó demasiado.',
          feedbackId: _state.feedbackId + 1,
        ),
      );
    }
  }

  void removeSelectedImage() {
    _emit(
      _state.copyWith(
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
    final validation = orchestrator.validateDraft(_state);
    if (!validation.isValid) {
      _emitValidationErrors(validation);
      return;
    }

    await _submit(saveAsDraft: true);
  }

  Future<void> publish() async {
    final validation = orchestrator.validatePublish(_state);
    if (!validation.isValid) {
      _emitValidationErrors(validation);
      return;
    }

    await _submit(saveAsDraft: false);
  }

  Future<void> _loadArticle(String articleId) async {
    final result = await orchestrator.loadArticle(articleId).timeout(timeout);

    if (result is DataFailed<ArticleAuthoringEntity> || result.data == null) {
      _emitFailure('No pudimos cargar la nota para editarla.');
      return;
    }

    final article = result.data!;
    if (_currentUser?.id != article.author.id) {
      _emitFailure('No tenés permisos para editar esta nota.');
      return;
    }

    _initialArticle = article;

    _emit(
      _state.copyWith(
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
      _emitFailure('No se pudo resolver el autor de la nota.');
      return;
    }

    _emit(
      _state.copyWith(
        status: CreateEditArticleStatus.submitting,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final article = orchestrator.buildArticleFromState(
      state: _state,
      author: author,
      baseline: _initialArticle,
      publish: !saveAsDraft,
    );

    try {
      final result = saveAsDraft
          ? await orchestrator.saveDraft(article).timeout(timeout)
          : await orchestrator.publish(article).timeout(timeout);

      if (result is DataFailed<ArticleAuthoringEntity> || result.data == null) {
        _emit(
          _state.copyWith(
            status: CreateEditArticleStatus.failure,
            errorMessage: saveAsDraft
                ? 'No se pudo guardar el borrador. Intentá nuevamente.'
                : 'No se pudo publicar la nota. Intentá nuevamente.',
            feedbackId: _state.feedbackId + 1,
          ),
        );
        return;
      }

      final persistedArticle = result.data!;
      _initialArticle = persistedArticle;

      _emit(
        _state.copyWith(
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
          feedbackId: _state.feedbackId + 1,
        ),
      );
    } on TimeoutException {
      _emit(
        _state.copyWith(
          status: CreateEditArticleStatus.failure,
          errorMessage: saveAsDraft
              ? 'Guardar el borrador tardó demasiado. Intentá nuevamente.'
              : 'La publicación tardó demasiado. Intentá nuevamente.',
          feedbackId: _state.feedbackId + 1,
        ),
      );
    }
  }

  bool _resolveUnsavedChanges({
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    String? localImagePath,
  }) {
    return orchestrator.hasUnsavedChanges(
      state: _state,
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
    _emit(
      _state.copyWith(
        status: CreateEditArticleStatus.ready,
        titleError: validation.titleError,
        contentError: validation.contentError,
        imageError: validation.imageError,
        errorMessage: 'Revisá los campos obligatorios antes de continuar.',
        feedbackId: _state.feedbackId + 1,
      ),
    );
  }

  void _emitFailure(String message) {
    _emit(
      _state.copyWith(
        status: CreateEditArticleStatus.failure,
        errorMessage: message,
        feedbackId: _state.feedbackId + 1,
      ),
    );
  }

  CreateEditArticleState get _state => read();

  void _emit(CreateEditArticleState newState) => write(newState);
}
