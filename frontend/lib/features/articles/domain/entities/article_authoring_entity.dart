import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';

class ArticleAuthoringEntity extends Equatable {
  final String? firestoreId;
  final ArticleAuthorEntity author;
  final String title;
  final String? subtitle;
  final String category;
  final String content;
  final String? imageUrl;
  final bool isPublished;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const ArticleAuthoringEntity({
    this.firestoreId,
    required this.author,
    required this.title,
    this.subtitle,
    required this.category,
    required this.content,
    this.imageUrl,
    required this.isPublished,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  ArticleAuthoringEntity copyWith({
    String? firestoreId,
    ArticleAuthorEntity? author,
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    bool? isPublished,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return ArticleAuthoringEntity(
      firestoreId: firestoreId ?? this.firestoreId,
      author: author ?? this.author,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublished: isPublished ?? this.isPublished,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  List<Object?> get props => [
    firestoreId,
    author,
    title,
    subtitle,
    category,
    content,
    imageUrl,
    isPublished,
    isActive,
    createdAt,
    updatedAt,
    publishedAt,
  ];
}
