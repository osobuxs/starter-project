import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/paginated_articles_model.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article_pagination_cursor.dart';

abstract class ArticleFirestoreDataSource {
  Future<PaginatedArticlesModel> getPublishedArticles({
    ArticlePaginationCursor? after,
    DateTime? dateFilter,
  });

  Future<ArticleModel?> getArticleByFirestoreId(String articleId);
}

class ArticleFirestoreDataSourceImpl implements ArticleFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ArticleFirestoreDataSourceImpl(this._firestore);

  @override
  Future<PaginatedArticlesModel> getPublishedArticles({
    ArticlePaginationCursor? after,
    DateTime? dateFilter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(kArticlesCollection)
        .where('isActive', isEqualTo: true)
        .where('isPublished', isEqualTo: true);

    if (dateFilter != null) {
      final startOfDay = DateTime(
        dateFilter.year,
        dateFilter.month,
        dateFilter.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      query = query
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay));
    }

    query = query
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId);

    if (after != null) {
      query = query.startAfter([
        Timestamp.fromDate(after.createdAt),
        after.firestoreId,
      ]);
    }

    final snapshot = await query.limit(kDashboardPageSize).get();

    final articles = snapshot.docs
        .map(
          (document) => ArticleModel.fromRawData(
            _normalizeDocumentData(document.data()),
            documentId: document.id,
          ),
        )
        .toList();

    final nextCursor = snapshot.docs.isEmpty
        ? null
        : _buildCursor(snapshot.docs.last);

    return PaginatedArticlesModel(
      articles: articles,
      nextCursor: nextCursor,
      hasReachedMax: snapshot.docs.length < kDashboardPageSize,
    );
  }

  @override
  Future<ArticleModel?> getArticleByFirestoreId(String articleId) async {
    final snapshot = await _firestore
        .collection(kArticlesCollection)
        .doc(articleId)
        .get();

    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    return ArticleModel.fromRawData(
      _normalizeDocumentData(data),
      documentId: snapshot.id,
    );
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

  ArticlePaginationCursor? _buildCursor(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final createdAtRaw = document.data()['createdAt'];
    if (createdAtRaw is Timestamp) {
      return ArticlePaginationCursor(
        createdAt: createdAtRaw.toDate(),
        firestoreId: document.id,
      );
    }

    if (createdAtRaw is DateTime) {
      return ArticlePaginationCursor(
        createdAt: createdAtRaw,
        firestoreId: document.id,
      );
    }

    return null;
  }
}
