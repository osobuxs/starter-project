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

    return snapshot.docs
        .map(
          (document) => ArticleModel.fromRawData(
            _normalizeDocumentData(document.data()),
            documentId: document.id,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveFavoriteArticle(ArticleModel article) async {
    final favoritesCollection = _resolveFavoritesCollection(
      throwIfMissing: true,
    )!;
    final articleId = _resolveArticleId(article);

    await favoritesCollection.doc(articleId).set({
      ...article.toRawData(),
      'articleId': articleId,
      'favoritedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
}
