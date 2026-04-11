import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_mapper.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';

void main() {
  const author = ArticleAuthorEntity(
    id: 'author-1',
    name: 'Ada',
    email: 'ada@example.com',
    photoUrl: null,
  );

  final baseline = ArticleAuthoringEntity(
    firestoreId: 'article-1',
    author: author,
    title: 'Original',
    subtitle: null,
    category: 'Varios',
    content: 'Original content',
    imageUrl: null,
    isPublished: false,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    publishedAt: null,
  );

  group('CreateEditArticleMapper.buildArticleFromState', () {
    test('sets publishedAt when first publishing', () {
      final now = DateTime(2026, 1, 3);
      const state = CreateEditArticleState(
        articleId: 'article-1',
        title: 'Nuevo título',
        subtitle: '',
        category: ' ',
        content: 'Nuevo contenido',
        imageUrl: 'https://img.example.com/1.jpg',
      );

      final built = CreateEditArticleMapper.buildArticleFromState(
        state: state,
        baseline: baseline,
        author: author,
        publish: true,
        now: now,
      );

      expect(built.isPublished, isTrue);
      expect(built.publishedAt, now);
      expect(built.category, 'Varios');
      expect(built.subtitle, isNull);
    });

    test('keeps previous publishedAt when already published', () {
      final existingPublished = baseline.copyWith(
        isPublished: true,
        publishedAt: DateTime(2026, 1, 2),
      );
      final now = DateTime(2026, 1, 5);
      const state = CreateEditArticleState(
        articleId: 'article-1',
        title: 'Edited',
        category: 'Tech',
        content: 'Edited content',
        imageUrl: 'https://img.example.com/2.jpg',
      );

      final built = CreateEditArticleMapper.buildArticleFromState(
        state: state,
        baseline: existingPublished,
        author: author,
        publish: false,
        now: now,
      );

      expect(built.isPublished, isTrue);
      expect(built.publishedAt, DateTime(2026, 1, 2));
    });
  });

  group('CreateEditArticleMapper.hasUnsavedChanges', () {
    test('detects new draft modifications when baseline is null', () {
      const state = CreateEditArticleState(
        title: '',
        subtitle: '',
        category: '',
        content: '',
        imageUrl: null,
      );

      final changed = CreateEditArticleMapper.hasUnsavedChanges(
        state: state,
        baseline: null,
        title: 'Algo',
      );

      expect(changed, isTrue);
    });

    test('returns false when no effective changes for baseline', () {
      final state = CreateEditArticleState(
        title: baseline.title,
        subtitle: baseline.subtitle ?? '',
        category: baseline.category,
        content: baseline.content,
        imageUrl: baseline.imageUrl,
      );

      final changed = CreateEditArticleMapper.hasUnsavedChanges(
        state: state,
        baseline: baseline,
      );

      expect(changed, isFalse);
    });
  });
}
