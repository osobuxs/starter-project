import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/repository/article_authoring_repository.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';

const testUser = UserEntity(
  id: 'user-1',
  email: 'ada@example.com',
  displayName: 'Ada',
);

const testAuthor = ArticleAuthorEntity(
  id: 'user-1',
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  photoUrl: 'https://example.com/ada.png',
);

UserProfileEntity buildTestProfile({String name = 'Ada Lovelace'}) {
  return UserProfileEntity(
    uid: 'user-1',
    name: name,
    email: 'ada@example.com',
    photoUrl: 'https://example.com/ada.png',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

ArticleAuthoringEntity buildTestArticle({
  String title = 'Draft title',
  String content = 'Draft content',
  bool isPublished = false,
  bool isActive = true,
  String? imageUrl,
}) {
  return ArticleAuthoringEntity(
    firestoreId: 'article-1',
    author: testAuthor,
    title: title,
    subtitle: 'Subtitle',
    category: 'Tech',
    content: content,
    imageUrl: imageUrl,
    isPublished: isPublished,
    isActive: isActive,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

class FakeAuthRepository implements AuthRepository {
  Future<UserEntity?> Function()? getCurrentUserHandler;

  @override
  Future<UserEntity?> getCurrentUser() async {
    return getCurrentUserHandler?.call();
  }

  @override
  Future<DataState<UserEntity>> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DataState<void>> logout() {
    throw UnimplementedError();
  }

  @override
  Future<DataState<UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DataState<UserEntity>> signInWithGoogle() {
    throw UnimplementedError();
  }
}

class FakeUserProfileRepository implements UserProfileRepository {
  Future<DataState<UserProfileEntity>> Function(String uid)?
  getUserProfileHandler;

  @override
  Future<DataState<UserProfileEntity>> getUserProfile(String uid) async {
    return getUserProfileHandler?.call(uid) ??
        DataFailed(Exception('Profile handler missing'));
  }

  @override
  Future<DataState<void>> deleteProfilePhoto(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<DataState<String>> uploadProfilePhoto(String uid, String imagePath) {
    throw UnimplementedError();
  }

  @override
  Future<DataState<UserProfileEntity>> updateUserProfile(
    UserProfileEntity profile,
  ) {
    throw UnimplementedError();
  }
}

class FakeArticleAuthoringRepository implements ArticleAuthoringRepository {
  Future<DataState<ArticleAuthoringEntity>> Function(
    ArticleAuthoringEntity article,
  )?
  saveDraftHandler;
  Future<DataState<ArticleAuthoringEntity>> Function(
    ArticleAuthoringEntity article,
  )?
  publishHandler;
  Future<DataState<String>> Function(String authorId, String imagePath)?
  uploadImageHandler;
  Future<DataState<ArticleAuthoringEntity>> Function(String articleId)?
  getArticleByIdHandler;

  @override
  Future<DataState<ArticleAuthoringEntity>> getArticleById(String articleId) {
    return getArticleByIdHandler?.call(articleId) ??
        Future.value(DataFailed(Exception('Article handler missing')));
  }

  @override
  Future<DataState<List<ArticleAuthoringEntity>>> getArticlesByAuthorId(
    String authorId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<DataState<ArticleAuthoringEntity>> publishArticle(
    ArticleAuthoringEntity article,
  ) {
    return publishHandler?.call(article) ??
        Future.value(DataFailed(Exception('Publish handler missing')));
  }

  @override
  Future<DataState<ArticleAuthoringEntity>> saveDraft(
    ArticleAuthoringEntity article,
  ) {
    return saveDraftHandler?.call(article) ??
        Future.value(DataFailed(Exception('Save handler missing')));
  }

  @override
  Future<DataState<ArticleAuthoringEntity>> updateArticleActiveState(
    ArticleAuthoringEntity article,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<DataState<String>> uploadArticleImage(
    String authorId,
    String imagePath,
  ) {
    return uploadImageHandler?.call(authorId, imagePath) ??
        Future.value(DataFailed(Exception('Upload handler missing')));
  }
}
