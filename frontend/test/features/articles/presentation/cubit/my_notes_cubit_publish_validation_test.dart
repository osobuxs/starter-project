import 'package:flutter_test/flutter_test.dart';
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

class _StubGetCurrentUserUseCase extends Fake implements GetCurrentUserUseCase {
  final UserEntity? user;

  _StubGetCurrentUserUseCase(this.user);

  @override
  Future<UserEntity?> call({void params}) async => user;
}

class _StubGetMyArticlesUseCase extends Fake implements GetMyArticlesUseCase {
  final DataState<List<ArticleAuthoringEntity>> result;

  _StubGetMyArticlesUseCase(this.result);

  @override
  Future<DataState<List<ArticleAuthoringEntity>>> call({
    GetMyArticlesParams? params,
  }) async => result;
}

class _SpyPublishArticleUseCase extends Fake implements PublishArticleUseCase {
  int callCount = 0;

  @override
  Future<DataState<ArticleAuthoringEntity>> call({
    PublishArticleParams? params,
  }) async {
    callCount += 1;
    return DataFailed(Exception('not expected in this test'));
  }
}

class _StubUpdateArticleActiveStateUseCase extends Fake
    implements UpdateArticleActiveStateUseCase {
  @override
  Future<DataState<ArticleAuthoringEntity>> call({
    UpdateArticleActiveStateParams? params,
  }) async => DataFailed(Exception('not used in this test'));
}

void main() {
  late GetCurrentUserUseCase getCurrentUser;
  late GetMyArticlesUseCase getMyArticles;
  late _SpyPublishArticleUseCase publishArticle;
  late UpdateArticleActiveStateUseCase updateArticleActiveState;
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
    getCurrentUser = _StubGetCurrentUserUseCase(user);
    getMyArticles = _StubGetMyArticlesUseCase(
      DataSuccess<List<ArticleAuthoringEntity>>([article()]),
    );
    publishArticle = _SpyPublishArticleUseCase();
    updateArticleActiveState = _StubUpdateArticleActiveStateUseCase();

    cubit = MyNotesCubit(
      getCurrentUser: getCurrentUser,
      getMyArticles: getMyArticles,
      publishArticle: publishArticle,
      updateArticleActiveState: updateArticleActiveState,
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

    expect(publishArticle.callCount, 0);
  });
}
