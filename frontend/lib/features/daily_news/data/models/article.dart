import 'package:floor/floor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import '../../../../core/constants/constants.dart';

@Entity(tableName: 'article', primaryKeys: ['id'])
class ArticleModel extends ArticleEntity {
  const ArticleModel({
    int? id,
    String? firestoreId,
    String? authorId,
    String? author,
    String? authorPhotoUrl,
    String? title,
    String? description,
    String? category,
    String? url,
    String? urlToImage,
    String? publishedAt,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    bool? isActive,
    int? favoritesVersion,
  }) : super(
         id: id,
         firestoreId: firestoreId,
         authorId: authorId,
         author: author,
         authorPhotoUrl: authorPhotoUrl,
         title: title,
         description: description,
         category: category,
         url: url,
         urlToImage: urlToImage,
         publishedAt: publishedAt,
         content: content,
         createdAt: createdAt,
         updatedAt: updatedAt,
         isPublished: isPublished,
         isActive: isActive,
         favoritesVersion: favoritesVersion,
       );

  factory ArticleModel.fromRawData(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final createdAt =
        _toDateTime(map['createdAt']) ?? _toDateTime(map['publishedAt']);
    final updatedAt = _toDateTime(map['updatedAt']);
    final content = map['content'] as String? ?? '';
    final description = (map['description'] as String?)?.trim();

    return ArticleModel(
      id: _resolveLocalId(documentId, map['id']),
      firestoreId: documentId ?? map['firestoreId'] as String?,
      authorId: map['authorId'] as String?,
      author: map['authorName'] as String? ?? map['author'] as String? ?? '',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      title: map['title'] as String? ?? '',
      description: description != null && description.isNotEmpty
          ? description
          : _buildDescription(content),
      category: map['category'] as String?,
      url: map['url'] as String? ?? '',
      urlToImage: _resolveImageUrl(map),
      publishedAt: _resolvePublishedAtLabel(createdAt, map['publishedAt']),
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublished: map['isPublished'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      favoritesVersion: _toInt(map['favoritesVersion']) ?? 0,
    );
  }

  factory ArticleModel.fromJson(Map<String, dynamic> map) {
    return ArticleModel.fromRawData(map);
  }

  factory ArticleModel.fromEntity(ArticleEntity entity) {
    return ArticleModel(
      id: entity.id,
      firestoreId: entity.firestoreId,
      authorId: entity.authorId,
      author: entity.author,
      authorPhotoUrl: entity.authorPhotoUrl,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      url: entity.url,
      urlToImage: entity.urlToImage,
      publishedAt: entity.publishedAt,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPublished: entity.isPublished,
      isActive: entity.isActive,
      favoritesVersion: entity.favoritesVersion,
    );
  }

  ArticleEntity toEntity() {
    return ArticleEntity(
      id: id,
      firestoreId: firestoreId,
      authorId: authorId,
      author: author,
      authorPhotoUrl: authorPhotoUrl,
      title: title,
      description: description,
      category: category,
      url: url,
      urlToImage: urlToImage,
      publishedAt: publishedAt,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublished: isPublished,
      isActive: isActive,
      favoritesVersion: favoritesVersion,
    );
  }

  Map<String, dynamic> toRawData() {
    return {
      'id': id,
      'firestoreId': firestoreId,
      'authorId': authorId,
      'author': author,
      'authorName': author,
      'authorPhotoUrl': authorPhotoUrl,
      'title': title,
      'description': description,
      'category': category,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublished': isPublished,
      'isActive': isActive,
      'favoritesVersion': favoritesVersion,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static int? _resolveLocalId(String? documentId, dynamic rawId) {
    if (rawId is int) {
      return rawId;
    }

    if (rawId is String && rawId.isNotEmpty) {
      return rawId.hashCode.abs();
    }

    if (documentId != null && documentId.isNotEmpty) {
      return documentId.hashCode.abs();
    }

    return null;
  }

  static String _resolveImageUrl(Map<String, dynamic> map) {
    final thumbnailUrl = map['thumbnailUrl'] as String?;
    final urlToImage = map['urlToImage'] as String?;

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return thumbnailUrl;
    }

    if (urlToImage != null && urlToImage.isNotEmpty) {
      return urlToImage;
    }

    return kDefaultImage;
  }

  static String _resolvePublishedAtLabel(
    DateTime? createdAt,
    dynamic publishedAt,
  ) {
    if (publishedAt is String && publishedAt.isNotEmpty) {
      return publishedAt;
    }

    if (createdAt == null) {
      return '';
    }

    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '${createdAt.year}-$month-$day';
  }

  static String _buildDescription(String content) {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      return '';
    }

    if (normalizedContent.length <= 140) {
      return normalizedContent;
    }

    return '${normalizedContent.substring(0, 140).trim()}...';
  }
}
