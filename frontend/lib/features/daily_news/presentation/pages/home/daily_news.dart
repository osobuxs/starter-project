import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';

import '../../../domain/entities/article.dart';
import '../../widgets/article_tile.dart';

class DailyNews extends StatelessWidget {
  const DailyNews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  Widget _buildPage(BuildContext context) {
    return BlocBuilder<RemoteArticlesBloc, RemoteArticlesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppSectionScaffold(
            title: 'Daily News',
            currentRouteName: AppRouteNames.dashboard,
            body: const Center(child: CupertinoActivityIndicator()),
          );
        }

        if (state.error != null && state.articles.isEmpty) {
          return AppSectionScaffold(
            title: 'Daily News',
            currentRouteName: AppRouteNames.dashboard,
            body: Center(
              child: IconButton(
                onPressed: () {
                  context.read<RemoteArticlesBloc>().add(
                    GetArticles(selectedDate: state.selectedDate),
                  );
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        return _buildArticlesPage(context, state);
      },
    );
  }

  Widget _buildArticlesPage(BuildContext context, RemoteArticlesState state) {
    final articles = state.articles;

    return AppSectionScaffold(
      title: 'Daily News',
      currentRouteName: AppRouteNames.dashboard,
      actions: [
        IconButton(
          onPressed: () => _onShowSavedArticlesViewTapped(context),
          icon: const Icon(Icons.bookmark, color: Colors.black),
        ),
      ],
      body: Column(
        children: [
          _buildDateFilter(context, state),
          Expanded(
            child: articles.isEmpty
                ? _buildEmptyState()
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200 &&
                          !state.isLoadingMore &&
                          !state.hasReachedMax) {
                        context.read<RemoteArticlesBloc>().add(
                          const GetArticles(loadMore: true),
                        );
                      }

                      return false;
                    },
                    child: ListView.builder(
                      itemCount:
                          articles.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (index >= articles.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }

                        return ArticleWidget(
                          article: articles[index],
                          onArticlePressed: (article) =>
                              _onArticlePressed(context, article),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, RemoteArticlesState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => _onPickDate(context, state.selectedDate),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              state.selectedDate == null
                  ? 'Filtrar por fecha'
                  : DateFormat('dd/MM/yyyy').format(state.selectedDate!),
            ),
          ),
          if (state.selectedDate != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                context.read<RemoteArticlesBloc>().add(
                  const GetArticles(clearDateFilter: true),
                );
              },
              child: const Text('Limpiar'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Todavía no hay notas cargadas.',
          textAlign: TextAlign.center,
        ),
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
    final authState = context.read<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;

    if (isAuthenticated) {
      Navigator.pushNamed(context, AppRouteNames.myFavorites);
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Necesitás iniciar sesión'),
          content: const Text(
            'Para abrir "Mis favoritos" primero necesitás iniciar sesión. Después te llevamos automáticamente.',
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
    ).then((shouldContinue) {
      if (shouldContinue != true || !context.mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamed(AppRouteNames.login, arguments: AppRouteNames.myFavorites);
    });
  }

  Future<void> _onPickDate(BuildContext context, DateTime? selectedDate) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null || !context.mounted) {
      return;
    }

    context.read<RemoteArticlesBloc>().add(
      GetArticles(selectedDate: pickedDate),
    );
  }
}
