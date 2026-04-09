import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';

import '../../../domain/entities/article.dart';
import '../../widgets/article_tile.dart';

class DailyNews extends StatelessWidget {
  const DailyNews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  Widget _buildAppbar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Daily News',
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        GestureDetector(
          onTap: () => _onShowSavedArticlesViewTapped(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.bookmark, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi perfil'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigator.pushNamed(context, '/UserProfile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Crear noticia'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigator.pushNamed(context, '/CreateArticle');
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Mis notas'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigator.pushNamed(context, '/MyNotes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Mis favoritos'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigator.pushNamed(context, '/MyFavorites');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context);
              // TODO: context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    return BlocBuilder<RemoteArticlesBloc, RemoteArticlesState>(
      builder: (context, state) {
        if (state is RemoteArticlesLoading) {
          return Scaffold(
            appBar: _buildAppbar(context),
            drawer: _buildDrawer(context),
            body: const Center(child: CupertinoActivityIndicator()),
          );
        }
        if (state is RemoteArticlesError) {
          return Scaffold(
            appBar: _buildAppbar(context),
            drawer: _buildDrawer(context),
            body: const Center(child: Icon(Icons.refresh)),
          );
        }
        if (state is RemoteArticlesDone) {
          return _buildArticlesPage(context, state.articles!);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildArticlesPage(BuildContext context, List<ArticleEntity> articles) {
    return Scaffold(
      appBar: _buildAppbar(context),
      drawer: _buildDrawer(context),
      body: ListView.builder(
        itemCount: articles.length,
        itemBuilder: (_, index) => ArticleWidget(
          article: articles[index],
          onArticlePressed: (article) => _onArticlePressed(context, article),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: check auth, then Navigator.pushNamed(context, '/CreateArticle');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onArticlePressed(BuildContext context, ArticleEntity article) {
    Navigator.pushNamed(context, '/ArticleDetails', arguments: article);
  }

  void _onShowSavedArticlesViewTapped(BuildContext context) {
    Navigator.pushNamed(context, '/SavedArticles');
  }
}
