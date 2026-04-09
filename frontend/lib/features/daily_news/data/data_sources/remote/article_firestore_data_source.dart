import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

abstract class ArticleFirestoreDataSource {
  Future<List<ArticleModel>> getPublishedArticles({
    required int page,
    DateTime? dateFilter,
  });
}

class ArticleFirestoreDataSourceImpl implements ArticleFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ArticleFirestoreDataSourceImpl(this._firestore);

  @override
  Future<List<ArticleModel>> getPublishedArticles({
    required int page,
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

    final snapshot = await query
        .orderBy('createdAt', descending: true)
        .limit(page * kDashboardPageSize)
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
