import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

bool isVisibleFavoriteArticle(ArticleModel article) {
  return article.isActive == true && article.isPublished == true;
}

abstract class FavoriteFirestoreDataSource {
  Future<List<ArticleModel>> getFavoriteArticles();

  Future<void> saveFavoriteArticle(ArticleModel article);

  Future<void> removeFavoriteArticle(String articleId);
}

class FavoriteFirestoreDataSourceImpl implements FavoriteFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FavoriteFirestoreDataSourceImpl(this._firestore, this._auth);

  @override
  Future<List<ArticleModel>> getFavoriteArticles() async {
    final favoritesCollection = _resolveFavoritesCollection();
    if (favoritesCollection == null) {
      return const <ArticleModel>[];
    }

    final snapshot = await favoritesCollection
        .orderBy('favoritedAt', descending: true)
        .get();

    final lookupResults = await Future.wait(
      snapshot.docs.map(
        (favoriteDocument) =>
            _resolveFavoriteArticle(favoritesCollection, favoriteDocument),
      ),
    );

    final staleFavoriteIds = lookupResults
        .where((result) => result.shouldDelete)
        .map((result) => result.favoriteId)
        .toList();

    if (staleFavoriteIds.isNotEmpty) {
      await _deleteFavoritesById(favoritesCollection, staleFavoriteIds);
    }

    return lookupResults
        .map((result) => result.article)
        .whereType<ArticleModel>()
        .toList();
  }

  @override
  Future<void> saveFavoriteArticle(ArticleModel article) async {
    final favoritesCollection = _resolveFavoritesCollection(
      throwIfMissing: true,
    )!;
    final articleId = _resolveArticleId(article);

    if (article.isActive != true || article.isPublished != true) {
      throw Exception('Only active published articles can be favorited');
    }

    await favoritesCollection.doc(articleId).set({
      ..._buildFavoriteDocument(articleId: articleId, article: article),
      'favoritedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFavoriteArticle(String articleId) async {
    final favoritesCollection = _resolveFavoritesCollection(
      throwIfMissing: true,
    )!;
    await favoritesCollection.doc(articleId).delete();
  }

  CollectionReference<Map<String, dynamic>>? _resolveFavoritesCollection({
    bool throwIfMissing = false,
  }) {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return _firestore
          .collection(kUsersCollection)
          .doc(currentUser.uid)
          .collection(kFavoritesCollection);
    }

    if (throwIfMissing) {
      throw Exception('Authentication required');
    }

    return null;
  }

  String _resolveArticleId(ArticleModel article) {
    final firestoreId = article.firestoreId?.trim();
    if (firestoreId != null && firestoreId.isNotEmpty) {
      return firestoreId;
    }

    final localId = article.id;
    if (localId != null) {
      return localId.toString();
    }

    throw Exception('Article id is required to manage favorites');
  }

  Map<String, dynamic> _normalizeDocumentData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    final createdAt = normalized['createdAt'];
    final updatedAt = normalized['updatedAt'];

    if (createdAt is Timestamp) {
      normalized['createdAt'] = createdAt.toDate();
    }

    if (updatedAt is Timestamp) {
      normalized['updatedAt'] = updatedAt.toDate();
    }

    return normalized;
  }

  Future<_FavoriteArticleLookupResult> _resolveFavoriteArticle(
    CollectionReference<Map<String, dynamic>> favoritesCollection,
    QueryDocumentSnapshot<Map<String, dynamic>> favoriteDocument,
  ) async {
    final favoriteData = favoriteDocument.data();

    final articleId = _resolveFavoriteDocumentArticleId(
      favoriteDocument.id,
      favoriteData,
    );

    try {
      final articleSnapshot = await _firestore
          .collection(kArticlesCollection)
          .doc(articleId)
          .get();

      final articleData = articleSnapshot.data();
      if (!articleSnapshot.exists || articleData == null) {
        return _FavoriteArticleLookupResult.delete(favoriteDocument.id);
      }

      final normalizedArticleData = _normalizeDocumentData(articleData);
      final article = ArticleModel.fromRawData(
        normalizedArticleData,
        documentId: articleSnapshot.id,
      );

      if (!isVisibleFavoriteArticle(article)) {
        return _FavoriteArticleLookupResult.hidden(favoriteDocument.id);
      }

      await favoritesCollection
          .doc(favoriteDocument.id)
          .set(
            _buildFavoriteDocument(articleId: articleId, article: article),
            SetOptions(merge: true),
          );

      return _FavoriteArticleLookupResult.keep(
        favoriteId: favoriteDocument.id,
        article: article,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return _FavoriteArticleLookupResult.hidden(favoriteDocument.id);
      }

      rethrow;
    }
  }

  Future<void> _deleteFavoritesById(
    CollectionReference<Map<String, dynamic>> favoritesCollection,
    List<String> favoriteIds,
  ) async {
    final batch = _firestore.batch();

    for (final favoriteId in favoriteIds) {
      batch.delete(favoritesCollection.doc(favoriteId));
    }

    await batch.commit();
  }

  String _resolveFavoriteDocumentArticleId(
    String fallbackId,
    Map<String, dynamic> data,
  ) {
    final articleId = (data['articleId'] as String?)?.trim();
    if (articleId != null && articleId.isNotEmpty) {
      return articleId;
    }

    return fallbackId;
  }

  Map<String, dynamic> _buildFavoriteDocument({
    required String articleId,
    required ArticleModel article,
  }) {
    return {
      'articleId': articleId,
      'firestoreId': articleId,
      'authorId': article.authorId,
      'author': article.author,
      'authorPhotoUrl': article.authorPhotoUrl,
      'title': article.title,
      'description': article.description,
      'category': article.category,
      'url': article.url,
      'urlToImage': article.urlToImage,
      'publishedAt': article.publishedAt,
      'content': article.content,
      'createdAt': article.createdAt,
      'updatedAt': article.updatedAt,
      'isPublished': article.isPublished ?? true,
      'isActive': article.isActive ?? true,
      'favoritesVersion': article.favoritesVersion ?? 0,
    };
  }
}

class _FavoriteArticleLookupResult {
  final String favoriteId;
  final ArticleModel? article;
  final bool shouldDelete;

  const _FavoriteArticleLookupResult._({
    required this.favoriteId,
    required this.article,
    required this.shouldDelete,
  });

  factory _FavoriteArticleLookupResult.keep({
    required String favoriteId,
    required ArticleModel article,
  }) {
    return _FavoriteArticleLookupResult._(
      favoriteId: favoriteId,
      article: article,
      shouldDelete: false,
    );
  }

  factory _FavoriteArticleLookupResult.hidden(String favoriteId) {
    return _FavoriteArticleLookupResult._(
      favoriteId: favoriteId,
      article: null,
      shouldDelete: false,
    );
  }

  factory _FavoriteArticleLookupResult.delete(String favoriteId) {
    return _FavoriteArticleLookupResult._(
      favoriteId: favoriteId,
      article: null,
      shouldDelete: true,
    );
  }
}
