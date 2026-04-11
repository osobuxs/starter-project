import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/favorite_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

void main() {
  group('isVisibleFavoriteArticle', () {
    test('returns true for active and published article', () {
      const article = ArticleModel(
        firestoreId: 'a1',
        isActive: true,
        isPublished: true,
      );

      expect(isVisibleFavoriteArticle(article), isTrue);
    });

    test('returns false for archived article', () {
      const article = ArticleModel(
        firestoreId: 'a1',
        isActive: false,
        isPublished: true,
      );

      expect(isVisibleFavoriteArticle(article), isFalse);
    });

    test('returns false for draft article', () {
      const article = ArticleModel(
        firestoreId: 'a1',
        isActive: true,
        isPublished: false,
      );

      expect(isVisibleFavoriteArticle(article), isFalse);
    });
  });
}
