import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_article_by_id_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/save_article_draft_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/upload_article_image_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_mapper.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_validators.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';

class CreateEditArticleOrchestrator {
  final SaveArticleDraftUseCase _saveArticleDraft;
  final PublishArticleUseCase _publishArticle;
  final UploadArticleImageUseCase _uploadArticleImage;
  final GetArticleByIdUseCase _getArticleById;
  final GetCurrentUserUseCase _getCurrentUser;
  final GetUserProfileUseCase _getUserProfile;

  const CreateEditArticleOrchestrator({
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
       _getUserProfile = getUserProfile;

  Future<UserEntity?> getCurrentUser() => _getCurrentUser();

  Future<DataState<ArticleAuthoringEntity>> loadArticle(String articleId) {
    return _getArticleById(params: GetArticleByIdParams(articleId: articleId));
  }

  Future<DataState<String>> uploadImage({
    required String authorId,
    required String imagePath,
  }) {
    return _uploadArticleImage(
      params: UploadArticleImageParams(
        authorId: authorId,
        imagePath: imagePath,
      ),
    );
  }

  Future<DataState<ArticleAuthoringEntity>> saveDraft(
    ArticleAuthoringEntity article,
  ) {
    return _saveArticleDraft(params: SaveArticleDraftParams(article: article));
  }

  Future<DataState<ArticleAuthoringEntity>> publish(
    ArticleAuthoringEntity article,
  ) {
    return _publishArticle(params: PublishArticleParams(article: article));
  }

  Future<ArticleAuthorEntity> buildAuthor(UserEntity user) async {
    try {
      final profileResult = await _getUserProfile(
        params: GetUserProfileParams(uid: user.id),
      );

      if (profileResult is DataSuccess<UserProfileEntity> &&
          profileResult.data != null) {
        final profile = profileResult.data!;
        return ArticleAuthorEntity(
          id: user.id,
          name: profile.name.trim().isEmpty
              ? fallbackAuthorName(user)
              : profile.name,
          email: profile.email,
          photoUrl: profile.photoUrl,
        );
      }
    } on Exception {
      // fallback below
    }

    return ArticleAuthorEntity(
      id: user.id,
      name: fallbackAuthorName(user),
      email: user.email,
      photoUrl: null,
    );
  }

  ArticleAuthoringEntity buildEmptyArticle(ArticleAuthorEntity author) {
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

  ArticleAuthoringEntity buildArticleFromState({
    required CreateEditArticleState state,
    required ArticleAuthorEntity author,
    required ArticleAuthoringEntity? baseline,
    required bool publish,
  }) {
    return CreateEditArticleMapper.buildArticleFromState(
      state: state,
      baseline: baseline ?? buildEmptyArticle(author),
      author: author,
      publish: publish,
      now: DateTime.now(),
    );
  }

  bool hasUnsavedChanges({
    required CreateEditArticleState state,
    required ArticleAuthoringEntity? baseline,
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    String? localImagePath,
  }) {
    return CreateEditArticleMapper.hasUnsavedChanges(
      state: state,
      baseline: baseline,
      title: title,
      subtitle: subtitle,
      category: category,
      content: content,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
    );
  }

  CreateEditArticleValidation validateDraft(CreateEditArticleState state) {
    return CreateEditArticleValidators.validateDraft(state);
  }

  CreateEditArticleValidation validatePublish(CreateEditArticleState state) {
    return CreateEditArticleValidators.validatePublish(state);
  }

  String fallbackAuthorName(UserEntity user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    if (user.email.trim().isNotEmpty) {
      return user.email.trim();
    }

    return 'Autor';
  }
}
