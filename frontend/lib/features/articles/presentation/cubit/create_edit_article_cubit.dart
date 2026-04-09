import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_article_by_id_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/save_article_draft_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/upload_article_image_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';

class CreateEditArticleCubit extends Cubit<CreateEditArticleState> {
  static const Duration _timeout = Duration(seconds: 15);

  final SaveArticleDraftUseCase _saveArticleDraft;
  final PublishArticleUseCase _publishArticle;
  final UploadArticleImageUseCase _uploadArticleImage;
  final GetArticleByIdUseCase _getArticleById;
  final GetCurrentUserUseCase _getCurrentUser;
  final GetUserProfileUseCase _getUserProfile;

  UserEntity? _currentUser;
  ArticleAuthorEntity? _currentAuthor;
  ArticleAuthoringEntity? _initialArticle;

  CreateEditArticleCubit({
    required SaveArticleDraftUseCase saveArticleDraft,
    required PublishArticleUseCase publishArticle,
    required UploadArticleImageUseCase uploadArticleImage,
    required GetArticleByIdUseCase getArticleById,
    required GetCurrentUserUseCase getCurrentUser,
    required GetUserProfileUseCase getUserProfile,
  }) : _saveArticleDraft = saveArticleDraft,
       _publishArticle = publishArticle,
       _uploadArticleImage = uploadArticleImage,
       _getArticleById = getArticleById,
       _getCurrentUser = getCurrentUser,
       _getUserProfile = getUserProfile,
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
      _currentUser = await _getCurrentUser().timeout(_timeout);
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

      _currentAuthor = await _buildAuthor(_currentUser!);

      if (articleId != null && articleId.isNotEmpty) {
        await _loadArticle(articleId);
        return;
      }

      _initialArticle = _buildEmptyArticle(_currentAuthor!);
      emit(
        state.copyWith(
          status: CreateEditArticleStatus.ready,
          isEditMode: false,
          isPublished: false,
          articleId: null,
          title: '',
          subtitle: '',
          category: 'Varios',
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
      final result = await _uploadArticleImage(
        params: UploadArticleImageParams(
          authorId: currentUser.id,
          imagePath: imagePath,
        ),
      ).timeout(_timeout);

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
    final validation = _validateDraft();
    if (!validation.isValid) {
      _emitValidationErrors(validation);
      return;
    }

    await _submit(saveAsDraft: true);
  }

  Future<void> publish() async {
    final validation = _validatePublish();
    if (!validation.isValid) {
      _emitValidationErrors(validation);
      return;
    }

    await _submit(saveAsDraft: false);
  }

  Future<void> _loadArticle(String articleId) async {
    final result = await _getArticleById(
      params: GetArticleByIdParams(articleId: articleId),
    ).timeout(_timeout);

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
          ? await _saveArticleDraft(
              params: SaveArticleDraftParams(article: article),
            ).timeout(_timeout)
          : await _publishArticle(
              params: PublishArticleParams(article: article),
            ).timeout(_timeout);

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

  Future<ArticleAuthorEntity> _buildAuthor(UserEntity user) async {
    try {
      final profileResult = await _getUserProfile(
        params: GetUserProfileParams(uid: user.id),
      ).timeout(_timeout);

      if (profileResult is DataSuccess<UserProfileEntity> &&
          profileResult.data != null) {
        final profile = profileResult.data!;
        return ArticleAuthorEntity(
          id: user.id,
          name: profile.name.trim().isEmpty
              ? _fallbackAuthorName(user)
              : profile.name,
          email: profile.email,
          photoUrl: profile.photoUrl,
        );
      }
    } on Exception {
      // Fallback to auth context below.
    }

    return ArticleAuthorEntity(
      id: user.id,
      name: _fallbackAuthorName(user),
      email: user.email,
      photoUrl: null,
    );
  }

  ArticleAuthoringEntity _buildEmptyArticle(ArticleAuthorEntity author) {
    final now = DateTime.now();
    return ArticleAuthoringEntity(
      author: author,
      title: '',
      subtitle: null,
      category: 'Varios',
      content: '',
      imageUrl: null,
      isPublished: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  ArticleAuthoringEntity _buildArticleFromState({
    required ArticleAuthorEntity author,
    required bool publish,
  }) {
    final baseline = _initialArticle ?? _buildEmptyArticle(author);
    final normalizedCategory = _normalizeCategory(state.category);
    final now = DateTime.now();
    final shouldRemainPublished = publish || baseline.isPublished;

    return ArticleAuthoringEntity(
      firestoreId: state.articleId,
      author: author,
      title: state.title.trim(),
      subtitle: _normalizeOptionalValue(state.subtitle),
      category: normalizedCategory,
      content: state.content.trim(),
      imageUrl: state.imageUrl,
      isPublished: shouldRemainPublished,
      isActive: baseline.isActive,
      createdAt: baseline.createdAt,
      updatedAt: now,
      publishedAt: shouldRemainPublished
          ? (baseline.publishedAt ?? (publish ? now : baseline.createdAt))
          : null,
    );
  }

  String _fallbackAuthorName(UserEntity user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    if (user.email.trim().isNotEmpty) {
      return user.email.trim();
    }

    return 'Autor';
  }

  String _normalizeCategory(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Varios' : trimmed;
  }

  String? _normalizeOptionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _resolveUnsavedChanges({
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    String? localImagePath,
  }) {
    final baseline = _initialArticle;
    if (baseline == null) {
      return (title ?? state.title).trim().isNotEmpty ||
          (subtitle ?? state.subtitle).trim().isNotEmpty ||
          _normalizeCategory(category ?? state.category) != 'Varios' ||
          (content ?? state.content).trim().isNotEmpty ||
          ((imageUrl ?? state.imageUrl)?.trim().isNotEmpty ?? false) ||
          ((localImagePath ?? state.localImagePath)?.trim().isNotEmpty ??
              false);
    }

    return baseline.title != (title ?? state.title).trim() ||
        (baseline.subtitle ?? '') != (subtitle ?? state.subtitle).trim() ||
        baseline.category != _normalizeCategory(category ?? state.category) ||
        baseline.content != (content ?? state.content).trim() ||
        (baseline.imageUrl ?? '') != ((imageUrl ?? state.imageUrl) ?? '') ||
        ((localImagePath ?? state.localImagePath)?.trim().isNotEmpty ?? false);
  }

  _ArticleValidation _validateDraft() {
    final title = state.title.trim();
    return _ArticleValidation(
      titleError: title.isEmpty
          ? 'Ingresá al menos un título para guardar el borrador.'
          : null,
    );
  }

  _ArticleValidation _validatePublish() {
    final title = state.title.trim();
    final content = state.content.trim();
    final imageUrl = state.imageUrl?.trim() ?? '';

    return _ArticleValidation(
      titleError: title.isEmpty
          ? 'El título es obligatorio para publicar.'
          : null,
      contentError: content.isEmpty
          ? 'El contenido es obligatorio para publicar.'
          : null,
      imageError: imageUrl.isEmpty
          ? 'La imagen es obligatoria para publicar.'
          : null,
    );
  }

  void _emitValidationErrors(_ArticleValidation validation) {
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

class _ArticleValidation {
  final String? titleError;
  final String? contentError;
  final String? imageError;

  const _ArticleValidation({
    this.titleError,
    this.contentError,
    this.imageError,
  });

  bool get isValid =>
      titleError == null && contentError == null && imageError == null;
}
