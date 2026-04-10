import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/core/navigation/auth_redirect.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';

import '../../../../../injection_container.dart';
import '../../../domain/entities/article.dart';
import '../../bloc/article/local/local_article_bloc.dart';
import '../../bloc/article/local/local_article_event.dart';
import '../../bloc/article/local/local_article_state.dart';

class ArticleDetailsView extends HookWidget {
  final ArticleEntity? article;

  const ArticleDetailsView({Key? key, this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasLoadedFavorites = useRef(false);

    return BlocProvider(
      create: (_) => sl<LocalArticleBloc>()..add(const GetSavedArticles()),
      child: BlocListener<LocalArticleBloc, LocalArticlesState>(
        listenWhen: (previous, current) =>
            current is LocalArticlesDone || current is LocalArticlesError,
        listener: (context, state) {
          if (state is LocalArticlesError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red.shade700,
                  content: Text(
                    state.message ?? 'No pudimos actualizar favoritos.',
                  ),
                ),
              );
            return;
          }

          if (state is! LocalArticlesDone) {
            return;
          }

          if (!hasLoadedFavorites.value) {
            hasLoadedFavorites.value = true;
            return;
          }

          final message = state.message;
          if (message == null || message.isEmpty) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(backgroundColor: Colors.black, content: Text(message)),
            );
        },
        child: AppSectionScaffold(
          title: 'Detalle de noticia',
          currentRouteName: AppRouteNames.articleDetails,
          body: _buildBody(),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final currentArticle = article;
    if (currentArticle == null) {
      return const Center(child: Text('No encontramos la noticia.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(currentArticle),
          const SizedBox(height: 16),
          _buildArticleImage(currentArticle),
          const SizedBox(height: 16),
          _buildContentCard(currentArticle),
          const SizedBox(height: 16),
          _buildFooterCard(currentArticle),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ArticleEntity article) {
    final subtitle = _resolveSubtitle(article);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title?.trim().isNotEmpty == true
                  ? article.title!
                  : 'Sin título',
              style: const TextStyle(
                fontFamily: 'Butler',
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArticleImage(ArticleEntity article) {
    final imageUrl = article.urlToImage?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: 240,
        child: imageUrl == null || imageUrl.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: const Icon(Icons.image_outlined, size: 48),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CupertinoActivityIndicator()),
                errorWidget: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  child: const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
      ),
    );
  }

  Widget _buildContentCard(ArticleEntity article) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _resolveBody(article),
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildFooterCard(ArticleEntity article) {
    final authorName = article.author?.trim().isNotEmpty == true
        ? article.author!.trim()
        : 'autor desconocido';
    final dateLabel = _formatPublishedAt(article);
    final hasAuthorPhoto = article.authorPhotoUrl?.trim().isNotEmpty == true;

    return Builder(
      builder: (context) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (hasAuthorPhoto) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(
                      article.authorPhotoUrl!.trim(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publicado por $authorName',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (dateLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Fecha de publicación: $dateLabel',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    final currentArticle = article;
    if (currentArticle == null) {
      return const SizedBox.shrink();
    }

    if (currentArticle.isPublished != true || currentArticle.isActive != true) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        return BlocBuilder<LocalArticleBloc, LocalArticlesState>(
          builder: (context, state) {
            final savedArticles = state.articles ?? const <ArticleEntity>[];
            final isFavorite = _isFavorite(savedArticles);

            return FloatingActionButton.extended(
              heroTag: 'article_details_favorite_fab',
              onPressed: () => _onFloatingActionButtonPressed(
                context,
                isFavorite: isFavorite,
              ),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              label: Text(
                isFavorite ? 'En favoritos' : 'Guardar',
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
      },
    );
  }

  void _onFloatingActionButtonPressed(
    BuildContext context, {
    required bool isFavorite,
  }) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Necesitás iniciar sesión'),
            content: const Text(
              'Para guardar esta nota en favoritos primero necesitás iniciar sesión. Después te llevamos de vuelta a esta nota.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Ir al login'),
              ),
            ],
          );
        },
      );

      if (shouldContinue != true || !context.mounted) {
        return;
      }

      Navigator.of(context).pushNamed(
        AppRouteNames.login,
        arguments: AuthRedirectDestination(
          routeName: AppRouteNames.articleDetails,
          arguments: article,
        ),
      );
      return;
    }

    if (isFavorite) {
      BlocProvider.of<LocalArticleBloc>(context).add(RemoveArticle(article!));
      return;
    }

    BlocProvider.of<LocalArticleBloc>(context).add(SaveArticle(article!));
  }

  bool _isFavorite(List<ArticleEntity> savedArticles) {
    final currentArticle = article;
    if (currentArticle == null) {
      return false;
    }

    return savedArticles.any((savedArticle) {
      final firestoreId = currentArticle.firestoreId;
      if (firestoreId != null && firestoreId.isNotEmpty) {
        return savedArticle.firestoreId == firestoreId;
      }

      final currentId = currentArticle.id;
      if (currentId != null) {
        return savedArticle.id == currentId;
      }

      return savedArticle.title == currentArticle.title &&
          savedArticle.publishedAt == currentArticle.publishedAt;
    });
  }

  String? _resolveSubtitle(ArticleEntity article) {
    final subtitle = article.description?.trim();
    if (subtitle == null || subtitle.isEmpty) {
      return null;
    }

    final normalizedTitle = article.title?.trim() ?? '';
    if (subtitle == normalizedTitle) {
      return null;
    }

    return subtitle;
  }

  String _resolveBody(ArticleEntity article) {
    final body = article.content?.trim();
    if (body != null && body.isNotEmpty) {
      return body;
    }

    final subtitle = _resolveSubtitle(article);
    if (subtitle != null) {
      return subtitle;
    }

    return 'No hay contenido disponible para esta noticia.';
  }

  String _formatPublishedAt(ArticleEntity article) {
    final createdAt = article.createdAt;
    if (createdAt != null) {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }

    final parsedDate = DateTime.tryParse(article.publishedAt ?? '');
    if (parsedDate != null) {
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    }

    return article.publishedAt ?? '';
  }
}
