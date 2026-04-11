import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_orchestrator.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state_handlers.dart';

class CreateEditArticleCubit extends Cubit<CreateEditArticleState> {
  static const Duration timeout = Duration(seconds: 15);

  final CreateEditArticleOrchestrator orchestrator;
  late final CreateEditArticleStateHandlers _handlers;

  CreateEditArticleCubit({required this.orchestrator})
    : super(const CreateEditArticleState()) {
    _handlers = CreateEditArticleStateHandlers(
      orchestrator: orchestrator,
      read: () => state,
      write: emit,
      timeout: timeout,
    );
  }

  Future<void> initialize({String? articleId}) {
    return _handlers.initialize(articleId: articleId);
  }

  void onTitleChanged(String value) => _handlers.onTitleChanged(value);

  void onSubtitleChanged(String value) => _handlers.onSubtitleChanged(value);

  void onCategoryChanged(String value) => _handlers.onCategoryChanged(value);

  void onContentChanged(String value) => _handlers.onContentChanged(value);

  Future<void> uploadSelectedImage(String imagePath) {
    return _handlers.uploadSelectedImage(imagePath);
  }

  void removeSelectedImage() => _handlers.removeSelectedImage();

  Future<void> saveDraft() => _handlers.saveDraft();

  Future<void> publish() => _handlers.publish();
}
