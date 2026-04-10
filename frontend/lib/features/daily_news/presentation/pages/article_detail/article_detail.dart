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
          body: _buildBody(context),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final currentArticle = article;
    if (currentArticle == null) {
      return const Center(child: Text('No encontramos la noticia.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(currentArticle),
          const SizedBox(height: 16),
          _buildArticleImage(context, currentArticle),
          const SizedBox(height: 16),
          _buildContentCard(currentArticle),
          const SizedBox(height: 16),
          _buildFooterCard(currentArticle),
        ],
      ),
    );
  }

  Widget _buildHeader(ArticleEntity article) {
    final subtitle = _resolveSubtitle(article);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            article.title?.trim().isNotEmpty == true
                ? article.title!
                : 'Sin título',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Butler',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentCard(ArticleEntity article) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              _resolveBody(article),
              style: const TextStyle(fontSize: 18, height: 1.75),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleImage(BuildContext context, ArticleEntity article) {
    final imageUrl = article.urlToImage?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasImage ? () => _showImagePreview(context, article) : null,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 260,
              child: !hasImage
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
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                        ),
                      ),
                    ),
            ),
            if (hasImage)
              Positioned(
                right: 16,
                bottom: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Tocar para ampliar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
    final category = article.category?.trim();

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
                      if (category != null && category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Categoría: $category',
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
              backgroundColor: isFavorite
                  ? const Color(0xFFF3E5F5)
                  : const Color(0xFF4A148C),
              foregroundColor: isFavorite
                  ? const Color(0xFF4A148C)
                  : Colors.white,
              onPressed: () => _onFloatingActionButtonPressed(
                context,
                isFavorite: isFavorite,
              ),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
              ),
              label: Text(
                isFavorite ? 'En favoritos' : 'Guardar',
                style: TextStyle(
                  color: isFavorite ? const Color(0xFF4A148C) : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
      await navigateRequiringAuthentication(
        context,
        navigationContext: context,
        currentRouteName: AppRouteNames.articleDetails,
        destination: AuthRedirectDestination(
          routeName: AppRouteNames.articleDetails,
          arguments: article,
        ),
        actionLabel: 'guardar esta nota en favoritos',
        successMessage: 'Después te llevamos de vuelta a esta nota.',
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

  Future<void> _showImagePreview(BuildContext context, ArticleEntity article) {
    final imageUrl = article.urlToImage?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return Future<void>.value();
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const Center(child: CupertinoActivityIndicator()),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
