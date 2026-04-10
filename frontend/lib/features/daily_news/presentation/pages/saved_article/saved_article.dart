import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_dialogs.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/core/widgets/app_state_views.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/article.dart';
import '../../bloc/article/local/local_article_bloc.dart';
import '../../bloc/article/local/local_article_event.dart';
import '../../bloc/article/local/local_article_state.dart';
import '../../widgets/article_tile.dart';

class SavedArticles extends StatelessWidget {
  final String title;
  final String currentRouteName;

  const SavedArticles({
    Key? key,
    this.title = 'Mis favoritos',
    this.currentRouteName = AppRouteNames.myFavorites,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LocalArticleBloc>()..add(const GetSavedArticles()),
      child: AppSectionScaffold(
        title: title,
        currentRouteName: currentRouteName,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<LocalArticleBloc, LocalArticlesState>(
      builder: (context, state) {
        if (state is LocalArticlesLoading) {
          return const AppLoadingState(label: 'Cargando tus favoritos...');
        } else if (state is LocalArticlesDone) {
          return _buildArticlesList(state.articles!);
        } else if (state is LocalArticlesError) {
          return _buildErrorState(state.message);
        }
        return const AppLoadingState(label: 'Preparando tus favoritos...');
      },
    );
  }

  Widget _buildErrorState(String? message) {
    return AppCenteredMessageState(
      icon: Icons.favorite_outline,
      title: 'No pudimos cargar tus favoritos',
      message: message ?? 'Intentá nuevamente en unos segundos.',
      emphasized: true,
    );
  }

  Widget _buildArticlesList(List<ArticleEntity> articles) {
    if (articles.isEmpty) {
      return const AppCenteredMessageState(
        icon: Icons.favorite_border,
        title: 'Todavía no guardaste favoritos',
        message:
            'Cuando guardes una noticia como favorita, la vas a ver en esta sección.',
        emphasized: true,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ArticleWidget(
          article: articles[index],
          isRemovable: true,
          showCardContainer: true,
          onRemove: (article) => _onRemoveArticle(context, article),
          onArticlePressed: (article) => _onArticlePressed(context, article),
        );
      },
    );
  }

  Future<void> _onRemoveArticle(
    BuildContext context,
    ArticleEntity article,
  ) async {
    final shouldRemove = await showConfirmationDialog(
      context,
      title: 'Quitar de favoritos',
      message:
          '¿Querés quitar "${article.title?.trim().isNotEmpty == true ? article.title!.trim() : 'esta noticia'}" de tus favoritos?',
      confirmLabel: 'Quitar',
      isDestructive: true,
    );

    if (shouldRemove != true || !context.mounted) {
      return;
    }

    BlocProvider.of<LocalArticleBloc>(context).add(RemoveArticle(article));
  }

  void _onArticlePressed(BuildContext context, ArticleEntity article) {
    Navigator.pushNamed(
      context,
      AppRouteNames.articleDetails,
      arguments: article,
    );
  }
}
