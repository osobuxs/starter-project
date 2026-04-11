import 'package:news_app_clean_architecture/features/articles/domain/entities/article_author_entity.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';

class CreateEditArticleMapper {
  const CreateEditArticleMapper._();

  static ArticleAuthoringEntity buildArticleFromState({
    required CreateEditArticleState state,
    required ArticleAuthoringEntity baseline,
    required ArticleAuthorEntity author,
    required bool publish,
    required DateTime now,
  }) {
    final shouldRemainPublished = publish || baseline.isPublished;

    return ArticleAuthoringEntity(
      firestoreId: state.articleId,
      author: author,
      title: state.title.trim(),
      subtitle: normalizeOptionalValue(state.subtitle),
      category: normalizeCategory(state.category),
      content: state.content.trim(),
      imageUrl: state.imageUrl,
      isPublished: shouldRemainPublished,
      isActive: baseline.isActive,
      createdAt: baseline.createdAt,
      updatedAt: now,
      publishedAt: shouldRemainPublished
          ? (baseline.publishedAt ?? (publish ? now : baseline.createdAt))
          : null,
    );
  }

  static String normalizeCategory(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Varios' : trimmed;
  }

  static String? normalizeOptionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool hasUnsavedChanges({
    required CreateEditArticleState state,
    required ArticleAuthoringEntity? baseline,
    String? title,
    String? subtitle,
    String? category,
    String? content,
    String? imageUrl,
    String? localImagePath,
  }) {
    if (baseline == null) {
      return (title ?? state.title).trim().isNotEmpty ||
          (subtitle ?? state.subtitle).trim().isNotEmpty ||
          normalizeCategory(category ?? state.category) != 'Varios' ||
          (content ?? state.content).trim().isNotEmpty ||
          ((imageUrl ?? state.imageUrl)?.trim().isNotEmpty ?? false) ||
          ((localImagePath ?? state.localImagePath)?.trim().isNotEmpty ??
              false);
    }

    return baseline.title != (title ?? state.title).trim() ||
        (baseline.subtitle ?? '') != (subtitle ?? state.subtitle).trim() ||
        baseline.category != normalizeCategory(category ?? state.category) ||
        baseline.content != (content ?? state.content).trim() ||
        (baseline.imageUrl ?? '') != ((imageUrl ?? state.imageUrl) ?? '') ||
        ((localImagePath ?? state.localImagePath)?.trim().isNotEmpty ?? false);
  }
}
