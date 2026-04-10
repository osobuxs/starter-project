import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/articles/domain/entities/article_authoring_entity.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_state.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/pages/create_edit_article_page.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';

class MyNotesPage extends StatefulWidget {
  const MyNotesPage({super.key});

  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> {
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) {
      return;
    }

    context.read<MyNotesCubit>().initialize();
    _didInitialize = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyNotesCubit, MyNotesState>(
      listenWhen: (previous, current) =>
          previous.feedbackId != current.feedbackId ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        } else if (state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          _refreshDashboard(context);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.successMessage!)));
        }
      },
      builder: (context, state) {
        return AppSectionScaffold(
          title: 'Mis notas',
          currentRouteName: AppRouteNames.myNotes,
          floatingActionButton: FloatingActionButton(
            heroTag: 'my_notes_create_fab',
            onPressed: () => _openCreateArticle(context),
            child: const Icon(Icons.add),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MyNotesState state) {
    if (state.status == MyNotesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == MyNotesStatus.failure && state.articles.isEmpty) {
      return _MyNotesMessageState(
        icon: Icons.article_outlined,
        title: 'No pudimos cargar tus notas',
        message: 'Probá de nuevo en unos segundos.',
        actionLabel: 'Reintentar',
        onPressed: context.read<MyNotesCubit>().refresh,
      );
    }

    if (state.articles.isEmpty) {
      return _MyNotesMessageState(
        icon: Icons.edit_note_outlined,
        title: 'Todavía no creaste notas',
        message:
            'Cuando guardes un borrador o publiques una nota, la vas a ver acá.',
        actionLabel: 'Crear nota',
        onPressed: () => _openCreateArticle(context),
      );
    }

    return RefreshIndicator(
      onRefresh: context.read<MyNotesCubit>().refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = state.articles[index];
          return _MyNoteCard(
            article: article,
            isBusy: state.isBusy(article.firestoreId),
            onOpenDetails: () {
              _openArticleDetail(context, article);
            },
            onEdit: () => _openEditArticle(context, article),
            onPublish: article.isPublished
                ? null
                : () => context.read<MyNotesCubit>().publish(article),
            onDisable: article.isActive
                ? () => context.read<MyNotesCubit>().setActiveState(
                    article,
                    isActive: false,
                  )
                : null,
            onEnable: article.isActive
                ? null
                : () => context.read<MyNotesCubit>().setActiveState(
                    article,
                    isActive: true,
                  ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateArticle(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRouteNames.createArticle);
    if (!context.mounted) {
      return;
    }

    await context.read<MyNotesCubit>().refresh();
  }

  Future<void> _openEditArticle(
    BuildContext context,
    ArticleAuthoringEntity article,
  ) async {
    await Navigator.of(context).pushNamed(
      AppRouteNames.createArticle,
      arguments: CreateEditArticlePageArgs(articleId: article.firestoreId),
    );
    if (!context.mounted) {
      return;
    }

    await context.read<MyNotesCubit>().refresh();
  }

  Future<void> _openArticleDetail(
    BuildContext context,
    ArticleAuthoringEntity article,
  ) {
    return Navigator.of(context).pushNamed(
      AppRouteNames.articleDetails,
      arguments: _mapToArticleDetailEntity(article),
    );
  }

  ArticleEntity _mapToArticleDetailEntity(ArticleAuthoringEntity article) {
    return ArticleEntity(
      firestoreId: article.firestoreId,
      authorId: article.author.id,
      author: article.author.name,
      authorPhotoUrl: article.author.photoUrl,
      title: article.title,
      description: article.subtitle,
      category: article.category,
      urlToImage: article.imageUrl,
      publishedAt: article.publishedAt?.toIso8601String(),
      content: article.content,
      createdAt: article.createdAt,
      updatedAt: article.updatedAt,
      isPublished: article.isPublished,
      isActive: article.isActive,
    );
  }

  void _refreshDashboard(BuildContext context) {
    final remoteState = context.read<RemoteArticlesBloc>().state;
    context.read<RemoteArticlesBloc>().add(
      GetArticles(selectedDate: remoteState.selectedDate),
    );
  }
}

class _MyNoteCard extends StatelessWidget {
  final ArticleAuthoringEntity article;
  final bool isBusy;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;

  const _MyNoteCard({
    required this.article,
    required this.isBusy,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onPublish,
    required this.onDisable,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final preview = article.content.trim().isEmpty
        ? 'Sin contenido'
        : article.content.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleCardImage(imageUrl: article.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                article.title.trim().isEmpty
                                    ? 'Sin título'
                                    : article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ArticleStateBadge(article: article),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Creada el ${DateFormat('dd/MM/yyyy').format(article.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PopupMenuButton<_MyNoteAction>(
                          onSelected: (action) {
                            switch (action) {
                              case _MyNoteAction.edit:
                                onEdit();
                                break;
                              case _MyNoteAction.publish:
                                onPublish?.call();
                                break;
                              case _MyNoteAction.disable:
                                onDisable?.call();
                                break;
                              case _MyNoteAction.enable:
                                onEnable?.call();
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: _MyNoteAction.edit,
                              child: Text('Editar'),
                            ),
                            if (onPublish != null)
                              const PopupMenuItem(
                                value: _MyNoteAction.publish,
                                child: Text('Publicar'),
                              ),
                            if (onDisable != null)
                              const PopupMenuItem(
                                value: _MyNoteAction.disable,
                                child: Text('Archivar'),
                              ),
                            if (onEnable != null)
                              const PopupMenuItem(
                                value: _MyNoteAction.enable,
                                child: Text('Reactivar'),
                              ),
                          ],
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MyNoteAction { edit, publish, disable, enable }

class _ArticleCardImage extends StatelessWidget {
  final String? imageUrl;

  const _ArticleCardImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 110,
        height: 110,
        child: resolvedImageUrl == null || resolvedImageUrl.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: const Icon(Icons.image_outlined, size: 40),
              )
            : CachedNetworkImage(
                imageUrl: resolvedImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  child: const Icon(Icons.broken_image_outlined, size: 40),
                ),
              ),
      ),
    );
  }
}

class _ArticleStateBadge extends StatelessWidget {
  final ArticleAuthoringEntity article;

  const _ArticleStateBadge({required this.article});

  @override
  Widget build(BuildContext context) {
    final presentation = _resolveBadgePresentation();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: presentation.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        presentation.label,
        style: TextStyle(
          color: presentation.foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgePresentation _resolveBadgePresentation() {
    if (!article.isActive) {
      return const _BadgePresentation(
        label: 'Archivada',
        backgroundColor: Color(0xFFE0E0E0),
        foregroundColor: Color(0xFF424242),
      );
    }

    if (article.isPublished) {
      return const _BadgePresentation(
        label: 'Publicada',
        backgroundColor: Color(0xFFE3F2FD),
        foregroundColor: Color(0xFF1565C0),
      );
    }

    return const _BadgePresentation(
      label: 'Borrador',
      backgroundColor: Color(0xFFFFF3E0),
      foregroundColor: Color(0xFFEF6C00),
    );
  }
}

class _BadgePresentation {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _BadgePresentation({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class _MyNotesMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _MyNotesMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
