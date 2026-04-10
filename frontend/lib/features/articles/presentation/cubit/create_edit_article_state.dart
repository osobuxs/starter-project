import 'package:equatable/equatable.dart';

enum CreateEditArticleStatus { initial, loading, ready, submitting, failure }

class CreateEditArticleState extends Equatable {
  final CreateEditArticleStatus status;
  final bool isEditMode;
  final bool isPublished;
  final String? articleId;
  final String title;
  final String subtitle;
  final String category;
  final String content;
  final String? imageUrl;
  final String? localImagePath;
  final bool isUploadingImage;
  final bool hasUnsavedChanges;
  final String? titleError;
  final String? contentError;
  final String? imageError;
  final String? errorMessage;
  final String? successMessage;
  final int feedbackId;

  const CreateEditArticleState({
    this.status = CreateEditArticleStatus.initial,
    this.isEditMode = false,
    this.isPublished = false,
    this.articleId,
    this.title = '',
    this.subtitle = '',
    this.category = 'Varios',
    this.content = '',
    this.imageUrl,
    this.localImagePath,
    this.isUploadingImage = false,
    this.hasUnsavedChanges = false,
    this.titleError,
    this.contentError,
    this.imageError,
    this.errorMessage,
    this.successMessage,
    this.feedbackId = 0,
  });

  bool get canSaveDraft =>
      status != CreateEditArticleStatus.loading &&
      status != CreateEditArticleStatus.submitting &&
      !isPublished &&
      hasUnsavedChanges &&
      title.trim().isNotEmpty &&
      !isUploadingImage;

  bool get canPublish =>
      status != CreateEditArticleStatus.loading &&
      status != CreateEditArticleStatus.submitting &&
      hasUnsavedChanges &&
      title.trim().isNotEmpty &&
      content.trim().isNotEmpty &&
      imageUrl != null &&
      imageUrl!.trim().isNotEmpty &&
      !isUploadingImage;

  CreateEditArticleState copyWith({
    CreateEditArticleStatus? status,
    bool? isEditMode,
    bool? isPublished,
    String? articleId,
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    bool clearImageUrl = false,
    String? localImagePath,
    bool clearLocalImagePath = false,
    bool? isUploadingImage,
    bool? hasUnsavedChanges,
    String? titleError,
    bool clearTitleError = false,
    String? contentError,
    bool clearContentError = false,
    String? imageError,
    bool clearImageError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    int? feedbackId,
  }) {
    return CreateEditArticleState(
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      isPublished: isPublished ?? this.isPublished,
      articleId: articleId ?? this.articleId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      content: content ?? this.content,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePath ?? this.localImagePath),
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      titleError: clearTitleError ? null : (titleError ?? this.titleError),
      contentError: clearContentError
          ? null
          : (contentError ?? this.contentError),
      imageError: clearImageError ? null : (imageError ?? this.imageError),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      feedbackId: feedbackId ?? this.feedbackId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isEditMode,
    isPublished,
    articleId,
    title,
    subtitle,
    category,
    content,
    imageUrl,
    localImagePath,
    isUploadingImage,
    hasUnsavedChanges,
    titleError,
    contentError,
    imageError,
    errorMessage,
    successMessage,
    feedbackId,
  ];
}
