import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
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
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is LocalArticlesDone) {
          return _buildArticlesList(state.articles!);
        } else if (state is LocalArticlesError) {
          return _buildErrorState(state.message);
        }
        return Container();
      },
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message ?? 'No pudimos cargar tus favoritos.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildArticlesList(List<ArticleEntity> articles) {
    if (articles.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no tenés favoritos guardados. Cuando guardes una nota, la vas a ver acá.',
          style: TextStyle(color: Colors.black),
        ),
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
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Quitar de favoritos'),
          content: Text(
            '¿Querés quitar "${article.title?.trim().isNotEmpty == true ? article.title!.trim() : 'esta nota'}" de tus favoritos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Quitar'),
            ),
          ],
        );
      },
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
