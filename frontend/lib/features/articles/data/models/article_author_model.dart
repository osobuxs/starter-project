import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';

class ArticleAuthorModel extends ArticleAuthorEntity {
  const ArticleAuthorModel({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
  });

  factory ArticleAuthorModel.fromRawData(Map<String, dynamic> map) {
    return ArticleAuthorModel(
      id: map['id'] as String? ?? map['authorId'] as String? ?? '',
      name: map['name'] as String? ?? map['authorName'] as String? ?? '',
      email: map['email'] as String? ?? map['authorEmail'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['authorPhotoUrl'] as String?,
    );
  }

  factory ArticleAuthorModel.fromEntity(ArticleAuthorEntity entity) {
    return ArticleAuthorModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      photoUrl: entity.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': id,
      'authorName': name,
      'authorEmail': email,
      'authorPhotoUrl': photoUrl,
    };
  }

  ArticleAuthorEntity toEntity() {
    return ArticleAuthorEntity(
      id: id,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }
}
