import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_article_by_id_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/save_article_draft_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/upload_article_image_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_orchestrator.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';
import '../../support/editor_test_fakes.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeUserProfileRepository profileRepository;
  late FakeArticleAuthoringRepository articleRepository;
  late CreateEditArticleOrchestrator orchestrator;

  setUp(() {
    authRepository = FakeAuthRepository();
    profileRepository = FakeUserProfileRepository();
    articleRepository = FakeArticleAuthoringRepository();

    orchestrator = CreateEditArticleOrchestrator(
      saveArticleDraft: SaveArticleDraftUseCase(articleRepository),
      publishArticle: PublishArticleUseCase(articleRepository),
      uploadArticleImage: UploadArticleImageUseCase(articleRepository),
      getArticleById: GetArticleByIdUseCase(articleRepository),
      getCurrentUser: GetCurrentUserUseCase(authRepository),
      getUserProfile: GetUserProfileUseCase(profileRepository),
    );
  });

  group('CreateEditArticleOrchestrator', () {
    test('buildAuthor uses profile data when available', () async {
      profileRepository.getUserProfileHandler = (_) async =>
          DataSuccess(buildTestProfile());

      final author = await orchestrator.buildAuthor(testUser);

      expect(author.name, 'Ada Lovelace');
      expect(author.photoUrl, 'https://example.com/ada.png');
    });

    test('buildAuthor falls back to auth context when profile fails', () async {
      profileRepository.getUserProfileHandler = (_) async =>
          DataFailed(Exception('profile failed'));

      final author = await orchestrator.buildAuthor(testUser);

      expect(author.name, 'Ada');
      expect(author.email, 'ada@example.com');
      expect(author.photoUrl, isNull);
    });
  });
}
