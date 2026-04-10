import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

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
      snapshot.docs.map(_resolveFavoriteArticle),
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
      'articleId': articleId,
      'favoritedAt': FieldValue.serverTimestamp(),
      'favoritesVersion': article.favoritesVersion ?? 0,
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

      final storedVersion = _toInt(favoriteData['favoritesVersion']) ?? 0;
      final currentVersion = article.favoritesVersion ?? 0;

      if (article.isActive != true ||
          article.isPublished != true ||
          storedVersion != currentVersion) {
        return _FavoriteArticleLookupResult.delete(favoriteDocument.id);
      }

      return _FavoriteArticleLookupResult.keep(
        favoriteId: favoriteDocument.id,
        article: article,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return _FavoriteArticleLookupResult.delete(favoriteDocument.id);
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

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
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

  factory _FavoriteArticleLookupResult.delete(String favoriteId) {
    return _FavoriteArticleLookupResult._(
      favoriteId: favoriteId,
      article: null,
      shouldDelete: true,
    );
  }
}
