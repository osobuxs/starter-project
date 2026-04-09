import 'package:equatable/equatable.dart';

class ArticleEntity extends Equatable {
  final int? id;
  final String? firestoreId;
  final String? authorId;
  final String? author;
  final String? authorPhotoUrl;
  final String? title;
  final String? description;
  final String? category;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isPublished;
  final bool? isActive;

  const ArticleEntity({
    this.id,
    this.firestoreId,
    this.authorId,
    this.author,
    this.authorPhotoUrl,
    this.title,
    this.description,
    this.category,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.content,
    this.createdAt,
    this.updatedAt,
    this.isPublished,
    this.isActive,
  });

  @override
  List<Object?> get props {
    return [
      id,
      firestoreId,
      authorId,
      author,
      authorPhotoUrl,
      title,
      description,
      category,
      url,
      urlToImage,
      publishedAt,
      content,
      createdAt,
      updatedAt,
      isPublished,
      isActive,
    ];
  }
}
