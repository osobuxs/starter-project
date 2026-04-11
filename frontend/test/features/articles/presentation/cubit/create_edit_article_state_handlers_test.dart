import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_article_by_id_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/save_article_draft_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/upload_article_image_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_orchestrator.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state_handlers.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/usecases/get_user_profile_usecase.dart';
import '../../support/editor_test_fakes.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeUserProfileRepository profileRepository;
  late FakeArticleAuthoringRepository articleRepository;
  late CreateEditArticleOrchestrator orchestrator;
  late CreateEditArticleState state;
  late CreateEditArticleStateHandlers handlers;
  late List<CreateEditArticleState> emissions;

  setUp(() {
    authRepository = FakeAuthRepository();
    profileRepository = FakeUserProfileRepository();
    articleRepository = FakeArticleAuthoringRepository();
    emissions = [];
    state = const CreateEditArticleState();

    orchestrator = CreateEditArticleOrchestrator(
      saveArticleDraft: SaveArticleDraftUseCase(articleRepository),
      publishArticle: PublishArticleUseCase(articleRepository),
      uploadArticleImage: UploadArticleImageUseCase(articleRepository),
      getArticleById: GetArticleByIdUseCase(articleRepository),
      getCurrentUser: GetCurrentUserUseCase(authRepository),
      getUserProfile: GetUserProfileUseCase(profileRepository),
    );

    handlers = CreateEditArticleStateHandlers(
      orchestrator: orchestrator,
      read: () => state,
      write: (newState) {
        state = newState;
        emissions.add(newState);
      },
      timeout: const Duration(milliseconds: 50),
    );
  });

  group('CreateEditArticleStateHandlers', () {
    test('initialize emits failure when user is unauthenticated', () async {
      authRepository.getCurrentUserHandler = () async => null;

      await handlers.initialize();

      expect(emissions, hasLength(2));
      expect(emissions.first.status, CreateEditArticleStatus.loading);
      expect(emissions.last.status, CreateEditArticleStatus.failure);
      expect(
        emissions.last.errorMessage,
        'Necesitás iniciar sesión para crear o editar una nota.',
      );
    });

    test(
      'uploadSelectedImage stores uploaded image and marks changes',
      () async {
        authRepository.getCurrentUserHandler = () async => testUser;
        profileRepository.getUserProfileHandler = (_) async =>
            DataSuccess(buildTestProfile());
        articleRepository.uploadImageHandler = (_, __) async =>
            const DataSuccess('https://example.com/image.png');

        await handlers.initialize();
        emissions.clear();

        await handlers.uploadSelectedImage('/tmp/image.png');

        expect(emissions.first.isUploadingImage, isTrue);
        expect(state.imageUrl, 'https://example.com/image.png');
        expect(state.hasUnsavedChanges, isTrue);
        expect(state.isUploadingImage, isFalse);
      },
    );

    test('saveDraft emits validation feedback for empty title', () async {
      await handlers.saveDraft();

      expect(state.status, CreateEditArticleStatus.ready);
      expect(state.titleError, isNotNull);
      expect(
        state.errorMessage,
        'Revisá los campos obligatorios antes de continuar.',
      );
    });
  });
}
