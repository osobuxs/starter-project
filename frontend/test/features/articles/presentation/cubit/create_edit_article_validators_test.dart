import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_validators.dart';

void main() {
  group('CreateEditArticleValidators.validateDraft', () {
    test('requires title', () {
      const state = CreateEditArticleState(title: '   ');

      final validation = CreateEditArticleValidators.validateDraft(state);

      expect(validation.isValid, isFalse);
      expect(validation.titleError, isNotNull);
    });

    test('accepts non-empty title', () {
      const state = CreateEditArticleState(title: 'Mi nota');

      final validation = CreateEditArticleValidators.validateDraft(state);

      expect(validation.isValid, isTrue);
      expect(validation.titleError, isNull);
    });
  });

  group('CreateEditArticleValidators.validatePublish', () {
    test('requires title, content and image', () {
      const state = CreateEditArticleState(
        title: ' ',
        content: ' ',
        imageUrl: null,
      );

      final validation = CreateEditArticleValidators.validatePublish(state);

      expect(validation.isValid, isFalse);
      expect(validation.titleError, isNotNull);
      expect(validation.contentError, isNotNull);
      expect(validation.imageError, isNotNull);
    });

    test('passes when all publish fields are complete', () {
      const state = CreateEditArticleState(
        title: 'Título',
        content: 'Contenido completo',
        imageUrl: 'https://img.example.com/pic.jpg',
      );

      final validation = CreateEditArticleValidators.validatePublish(state);

      expect(validation.isValid, isTrue);
      expect(validation.titleError, isNull);
      expect(validation.contentError, isNull);
      expect(validation.imageError, isNull);
    });
  });
}
