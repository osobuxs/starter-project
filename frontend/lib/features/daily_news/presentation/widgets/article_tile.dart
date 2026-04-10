import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/article.dart';

class ArticleWidget extends StatelessWidget {
  final ArticleEntity? article;
  final bool? isRemovable;
  final bool showCardContainer;
  final void Function(ArticleEntity article)? onRemove;
  final void Function(ArticleEntity article)? onArticlePressed;

  const ArticleWidget({
    Key? key,
    this.article,
    this.onArticlePressed,
    this.isRemovable = false,
    this.showCardContainer = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: _onTap,
      child: SizedBox(
        height: 164,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context),
              const SizedBox(width: 12),
              _buildTitleAndDescription(context),
              if (isRemovable == true) ...[
                const SizedBox(width: 8),
                _buildRemovableArea(),
              ],
            ],
          ),
        ),
      ),
    );

    if (!showCardContainer) {
      return content;
    }

    return Card(clipBehavior: Clip.antiAlias, child: content);
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = article?.urlToImage?.trim();

    Widget fallback(IconData icon) => ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 116,
        height: double.infinity,
        color: Colors.black.withOpacity(0.06),
        child: Icon(icon, color: Colors.black45),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return fallback(Icons.image_outlined);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 116,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
      ),
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          fallback(CupertinoIcons.photo),
      errorWidget: (context, url, error) =>
          fallback(Icons.broken_image_outlined),
    );
  }

  Widget _buildTitleAndDescription(BuildContext context) {
    final preview = _resolvePreview();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (article?.title?.trim().isNotEmpty == true)
                ? article!.title!
                : 'Sin título',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Butler',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              preview,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timeline_outlined, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatPublishedAt(article!),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemovableArea() {
    return IconButton(
      onPressed: _onRemove,
      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
      tooltip: 'Quitar de favoritos',
    );
  }

  String _resolvePreview() {
    final rawContent = article?.content?.trim();
    if (rawContent != null && rawContent.isNotEmpty) {
      return rawContent;
    }

    final rawDescription = article?.description?.trim();
    if (rawDescription != null && rawDescription.isNotEmpty) {
      return rawDescription;
    }

    return 'Sin contenido disponible.';
  }

  void _onTap() {
    if (onArticlePressed != null) {
      onArticlePressed!(article!);
    }
  }

  void _onRemove() {
    if (onRemove != null) {
      onRemove!(article!);
    }
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
