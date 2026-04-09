import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/articles/data/models/article_authoring_model.dart';

abstract class ArticleAuthoringFirestoreDataSource {
  Future<ArticleAuthoringModel> saveDraft(ArticleAuthoringModel article);

  Future<ArticleAuthoringModel> publishArticle(ArticleAuthoringModel article);

  Future<ArticleAuthoringModel> getArticleById(String articleId);

  Future<List<ArticleAuthoringModel>> getArticlesByAuthorId(String authorId);

  Future<ArticleAuthoringModel> updateArticleActiveState(
    ArticleAuthoringModel article,
  );
}

class ArticleAuthoringFirestoreDataSourceImpl
    implements ArticleAuthoringFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ArticleAuthoringFirestoreDataSourceImpl(this._firestore);

  @override
  Future<ArticleAuthoringModel> saveDraft(ArticleAuthoringModel article) {
    return _persistArticle(article);
  }

  @override
  Future<ArticleAuthoringModel> publishArticle(ArticleAuthoringModel article) {
    return _persistArticle(article);
  }

  @override
  Future<ArticleAuthoringModel> getArticleById(String articleId) async {
    final snapshot = await _firestore
        .collection(kArticlesCollection)
        .doc(articleId)
        .get();

    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw Exception('Article not found');
    }

    return ArticleAuthoringModel.fromRawData(data, documentId: snapshot.id);
  }

  @override
  Future<List<ArticleAuthoringModel>> getArticlesByAuthorId(
    String authorId,
  ) async {
    final snapshot = await _firestore
        .collection(kArticlesCollection)
        .where('authorId', isEqualTo: authorId)
        .get();

    final articles = snapshot.docs
        .map(
          (document) => ArticleAuthoringModel.fromRawData(
            document.data(),
            documentId: document.id,
          ),
        )
        .toList();

    articles.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return articles;
  }

  @override
  Future<ArticleAuthoringModel> updateArticleActiveState(
    ArticleAuthoringModel article,
  ) {
    return _persistArticle(article);
  }

  Future<ArticleAuthoringModel> _persistArticle(
    ArticleAuthoringModel article,
  ) async {
    final documentRef = article.firestoreId == null
        ? _firestore.collection(kArticlesCollection).doc()
        : _firestore.collection(kArticlesCollection).doc(article.firestoreId);

    final persistedModel = ArticleAuthoringModel(
      firestoreId: documentRef.id,
      author: article.author,
      title: article.title,
      subtitle: article.subtitle,
      category: article.category,
      content: article.content,
      imageUrl: article.imageUrl,
      isPublished: article.isPublished,
      isActive: article.isActive,
      createdAt: article.createdAt,
      updatedAt: article.updatedAt,
      publishedAt: article.publishedAt,
    );

    await documentRef.set(persistedModel.toMap(), SetOptions(merge: true));

    return persistedModel;
  }
}
