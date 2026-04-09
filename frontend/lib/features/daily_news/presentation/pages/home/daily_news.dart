import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
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

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      title: const Text('Daily News', style: TextStyle(color: Colors.black)),
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
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;

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
              _navigateFromDrawer(
                context,
                routeName: AppRouteNames.userProfile,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Crear noticia'),
            onTap: () {
              _navigateFromDrawer(
                context,
                routeName: AppRouteNames.createArticle,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Mis notas'),
            onTap: () {
              _navigateFromDrawer(context, routeName: AppRouteNames.myNotes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Mis favoritos'),
            onTap: () {
              _navigateFromDrawer(
                context,
                routeName: AppRouteNames.myFavorites,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isAuthenticated ? Icons.logout : Icons.person_add_alt,
            ),
            title: Text(isAuthenticated ? 'Cerrar sesión' : 'Crear cuenta'),
            onTap: () async {
              Navigator.pop(context);
              if (isAuthenticated) {
                final shouldLogout = await _showLogoutConfirmation(context);
                if (shouldLogout == true && context.mounted) {
                  context.read<AuthCubit>().logout();
                }
              } else {
                Navigator.pushNamed(context, AppRouteNames.register);
              }
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

  Widget _buildArticlesPage(
    BuildContext context,
    List<ArticleEntity> articles,
  ) {
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
    Navigator.pushNamed(
      context,
      AppRouteNames.articleDetails,
      arguments: article,
    );
  }

  void _onShowSavedArticlesViewTapped(BuildContext context) {
    Navigator.pushNamed(context, AppRouteNames.savedArticles);
  }

  void _navigateFromDrawer(BuildContext context, {required String routeName}) {
    final authState = context.read<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;

    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      isAuthenticated ? routeName : AppRouteNames.login,
      arguments: isAuthenticated ? null : routeName,
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Querés cerrar tu sesión actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
}
