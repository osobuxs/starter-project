import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/articles/data/models/article_author_model.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';

class ArticleAuthoringModel extends ArticleAuthoringEntity {
  const ArticleAuthoringModel({
    required super.firestoreId,
    required super.author,
    required super.title,
    super.subtitle,
    required super.category,
    required super.content,
    super.imageUrl,
    required super.isPublished,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
  });

  factory ArticleAuthoringModel.fromRawData(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawCategory = (map['category'] as String? ?? 'Varios').trim();

    return ArticleAuthoringModel(
      firestoreId: documentId ?? map['firestoreId'] as String?,
      author: ArticleAuthorModel.fromRawData(map).toEntity(),
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? map['description'] as String?,
      category: rawCategory.isEmpty ? 'Varios' : rawCategory,
      content: map['content'] as String? ?? '',
      imageUrl: map['urlToImage'] as String? ?? map['thumbnailUrl'] as String?,
      isPublished: map['isPublished'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt:
          _toDateTime(map['updatedAt']) ??
          _toDateTime(map['createdAt']) ??
          DateTime.now(),
      publishedAt: _toDateTime(map['publishedAt']),
    );
  }

  factory ArticleAuthoringModel.fromEntity(ArticleAuthoringEntity entity) {
    return ArticleAuthoringModel(
      firestoreId: entity.firestoreId,
      author: entity.author,
      title: entity.title,
      subtitle: entity.subtitle,
      category: entity.category,
      content: entity.content,
      imageUrl: entity.imageUrl,
      isPublished: entity.isPublished,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      publishedAt: entity.publishedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final authorModel = ArticleAuthorModel.fromEntity(author);

    return {
      ...authorModel.toMap(),
      'title': title,
      'subtitle': subtitle,
      'description': subtitle,
      'category': category,
      'content': content,
      'urlToImage': imageUrl,
      'thumbnailUrl': imageUrl,
      'isPublished': isPublished,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'publishedAt': publishedAt,
    };
  }

  ArticleAuthoringEntity toEntity() {
    return ArticleAuthoringEntity(
      firestoreId: firestoreId,
      author: author,
      title: title,
      subtitle: subtitle,
      category: category,
      content: content,
      imageUrl: imageUrl,
      isPublished: isPublished,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: publishedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
