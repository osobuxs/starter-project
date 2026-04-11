import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/get_my_articles_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/publish_article_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/domain/usecases/update_article_active_state_usecase.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';

class _MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class _MockGetMyArticlesUseCase extends Mock implements GetMyArticlesUseCase {}

class _MockPublishArticleUseCase extends Mock
    implements PublishArticleUseCase {}

class _MockUpdateArticleActiveStateUseCase extends Mock
    implements UpdateArticleActiveStateUseCase {}

void main() {
  late _MockGetCurrentUserUseCase getCurrentUser;
  late _MockGetMyArticlesUseCase getMyArticles;
  late _MockPublishArticleUseCase publishArticle;
  late _MockUpdateArticleActiveStateUseCase updateArticleActiveState;
  late MyNotesCubit cubit;

  const user = UserEntity(id: 'user-1', email: 'user@example.com');
  const author = ArticleAuthorEntity(
    id: 'user-1',
    name: 'Ada',
    email: 'user@example.com',
    photoUrl: null,
  );

  ArticleAuthoringEntity article({
    String title = 'Title',
    String content = 'Content',
    String? imageUrl = 'https://img.example.com/pic.jpg',
  }) {
    return ArticleAuthoringEntity(
      firestoreId: 'article-1',
      author: author,
      title: title,
      subtitle: null,
      category: 'Tech',
      content: content,
      imageUrl: imageUrl,
      isPublished: false,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      publishedAt: null,
    );
  }

  setUp(() {
    getCurrentUser = _MockGetCurrentUserUseCase();
    getMyArticles = _MockGetMyArticlesUseCase();
    publishArticle = _MockPublishArticleUseCase();
    updateArticleActiveState = _MockUpdateArticleActiveStateUseCase();

    cubit = MyNotesCubit(
      getCurrentUser: getCurrentUser,
      getMyArticles: getMyArticles,
      publishArticle: publishArticle,
      updateArticleActiveState: updateArticleActiveState,
    );

    when(getCurrentUser()).thenAnswer((_) async => user);
    when(getMyArticles(params: anyNamed('params'))).thenAnswer(
      (_) async => DataSuccess<List<ArticleAuthoringEntity>>([article()]),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('publish fails fast when required fields are missing', () async {
    await cubit.initialize();

    await cubit.publish(article(title: ' ', content: ' ', imageUrl: null));

    expect(cubit.state.status, MyNotesStatus.ready);
    expect(cubit.state.errorMessage, isNotNull);

    verifyNever(publishArticle(params: anyNamed('params')));
  });
}
