import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';

class CreateEditArticleValidation {
  final String? titleError;
  final String? contentError;
  final String? imageError;

  const CreateEditArticleValidation({
    this.titleError,
    this.contentError,
    this.imageError,
  });

  bool get isValid =>
      titleError == null && contentError == null && imageError == null;
}

class CreateEditArticleValidators {
  const CreateEditArticleValidators._();

  static CreateEditArticleValidation validateDraft(
    CreateEditArticleState state,
  ) {
    final title = state.title.trim();
    return CreateEditArticleValidation(
      titleError: title.isEmpty
          ? 'Ingresá al menos un título para guardar el borrador.'
          : null,
    );
  }

  static CreateEditArticleValidation validatePublish(
    CreateEditArticleState state,
  ) {
    final title = state.title.trim();
    final content = state.content.trim();
    final imageUrl = state.imageUrl?.trim() ?? '';

    return CreateEditArticleValidation(
      titleError: title.isEmpty
          ? 'El título es obligatorio para publicar.'
          : null,
      contentError: content.isEmpty
          ? 'El contenido es obligatorio para publicar.'
          : null,
      imageError: imageUrl.isEmpty
          ? 'La imagen es obligatoria para publicar.'
          : null,
    );
  }
}
