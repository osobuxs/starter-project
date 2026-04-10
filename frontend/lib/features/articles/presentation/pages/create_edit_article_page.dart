import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_dialogs.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';

class CreateEditArticlePageArgs {
  final String? articleId;

  const CreateEditArticlePageArgs({this.articleId});
}

class CreateEditArticlePage extends StatefulWidget {
  final CreateEditArticlePageArgs? args;

  const CreateEditArticlePage({super.key, this.args});

  @override
  State<CreateEditArticlePage> createState() => _CreateEditArticlePageState();
}

class _CreateEditArticlePageState extends State<CreateEditArticlePage> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) {
      return;
    }

    context.read<CreateEditArticleCubit>().initialize(
      articleId: widget.args?.articleId,
    );
    _didInitialize = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateEditArticleCubit, CreateEditArticleState>(
      listenWhen: (previous, current) =>
          previous.feedbackId != current.feedbackId ||
          previous.title != current.title ||
          previous.subtitle != current.subtitle ||
          previous.category != current.category ||
          previous.content != current.content,
      listener: (context, state) async {
        _syncControllers(state);

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          _refreshDashboard(context);

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.successMessage!)));

          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!context.mounted) {
            return;
          }

          Navigator.of(context).pushReplacementNamed(AppRouteNames.myNotes);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == CreateEditArticleStatus.loading;
        return WillPopScope(
          onWillPop: () => _confirmDiscardIfNeeded(context, state),
          child: AppSectionScaffold(
            title: state.isEditMode ? 'Editar nota' : 'Crear nota',
            currentRouteName: AppRouteNames.createArticle,
            onWillLeaveSection: () => _confirmDiscardIfNeeded(context, state),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CreateEditArticleState state) {
    final cubit = context.read<CreateEditArticleCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(context, state),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    onChanged: cubit.onTitleChanged,
                    textInputAction: TextInputAction.next,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Butler',
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Título',
                      hintText: 'Escribí un título claro para tu nota',
                      border: const OutlineInputBorder(),
                      errorText: state.titleError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subtitleController,
                    onChanged: cubit.onSubtitleChanged,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Subtítulo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _categoryController,
                    onChanged: cubit.onCategoryChanged,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Categoría (opcional)',
                      hintText: 'Ej: Tecnología, Cultura o Política',
                      helperText: 'Si la dejás vacía, guardamos "Varios".',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    onChanged: cubit.onContentChanged,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: 'Contenido',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      errorText: state.contentError,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _ArticleImagePicker(
                state: state,
                onPickImage: _onPickImage,
                onRemoveImage: context
                    .read<CreateEditArticleCubit>()
                    .removeSelectedImage,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!state.isPublished) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.canSaveDraft
                        ? context.read<CreateEditArticleCubit>().saveDraft
                        : null,
                    child: const Text('Guardar borrador'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: state.canPublish
                      ? context.read<CreateEditArticleCubit>().publish
                      : null,
                  child: Text(
                    state.isPublished ? 'Guardar cambios' : 'Publicar',
                  ),
                ),
              ),
            ],
          ),
          if (state.status == CreateEditArticleStatus.submitting) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, CreateEditArticleState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.isEditMode ? 'Editá tu nota' : 'Creá una nota nueva',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Butler',
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completá los campos principales, elegí una imagen y después guardá como borrador o publicá cuando esté lista.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null || !mounted) {
      return;
    }

    await context.read<CreateEditArticleCubit>().uploadSelectedImage(
      image.path,
    );
  }

  Future<bool> _confirmDiscardIfNeeded(
    BuildContext context,
    CreateEditArticleState state,
  ) async {
    if (!state.hasUnsavedChanges) {
      return true;
    }

    return showDiscardChangesDialog(context);
  }

  void _syncControllers(CreateEditArticleState state) {
    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }

    if (_subtitleController.text != state.subtitle) {
      _subtitleController.text = state.subtitle;
    }

    if (_categoryController.text != state.category) {
      _categoryController.text = state.category;
    }

    if (_contentController.text != state.content) {
      _contentController.text = state.content;
    }
  }

  void _refreshDashboard(BuildContext context) {
    final remoteState = context.read<RemoteArticlesBloc>().state;
    context.read<RemoteArticlesBloc>().add(
      GetArticles(selectedDate: remoteState.selectedDate),
    );
  }
}

class _ArticleImagePicker extends StatelessWidget {
  final CreateEditArticleState state;
  final Future<void> Function() onPickImage;
  final VoidCallback onRemoveImage;

  const _ArticleImagePicker({
    required this.state,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  bool get _hasImagePreview =>
      (state.localImagePath?.isNotEmpty ?? false) ||
      (state.imageUrl?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.isUploadingImage ? null : onPickImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            state.isUploadingImage
                ? 'Subiendo imagen...'
                : 'Seleccionar imagen',
          ),
        ),
        if (_hasImagePreview) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.isUploadingImage ? null : onRemoveImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Quitar imagen'),
            ),
          ),
        ],
        if (state.imageError != null) ...[
          const SizedBox(height: 8),
          Text(
            state.imageError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildImagePreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (state.localImagePath != null && state.localImagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(state.localImagePath!), fit: BoxFit.cover),
      );
    }

    if (state.imageUrl != null && state.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(state.imageUrl!, fit: BoxFit.cover),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Todavía no seleccionaste una imagen para la nota.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
