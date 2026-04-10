import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:news_app_clean_architecture/core/navigation/auth_redirect.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
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
            body: _buildErrorState(context, state),
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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount:
                          articles.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, index) {
                        if (index >= articles.length - 1) {
                          return const SizedBox(height: 0);
                        }

                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (_, index) {
                        if (index >= articles.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }

                        return ArticleWidget(
                          article: articles[index],
                          showCardContainer: true,
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
        heroTag: 'dashboard_create_article_fab',
        onPressed: () => _onCreateArticleTapped(context),
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
        child: Text('No existen notas.', textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, RemoteArticlesState state) {
    final presentation = _mapDashboardError(state.error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              presentation.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(presentation.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<RemoteArticlesBloc>().add(
                  GetArticles(selectedDate: state.selectedDate),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
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
    navigateRequiringAuthentication(
      context,
      navigationContext: context,
      currentRouteName: AppRouteNames.dashboard,
      destination: const AuthRedirectDestination(
        routeName: AppRouteNames.myFavorites,
      ),
      actionLabel: 'abrir "Mis favoritos"',
    );
  }

  Future<void> _onCreateArticleTapped(BuildContext context) {
    return navigateToProtectedRoute(
      context,
      navigationContext: context,
      currentRouteName: AppRouteNames.dashboard,
      routeName: AppRouteNames.createArticle,
      label: 'Crear noticia',
    );
  }

  _DashboardErrorPresentation _mapDashboardError(Exception? error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return const _DashboardErrorPresentation(
          title: 'No se pudieron cargar las noticias públicas',
          message:
              'Firestore rechazó la consulta. Revisá las reglas publicadas para permitir leer artículos activos y publicados.',
        );
      }

      if (error.code == 'unavailable') {
        return const _DashboardErrorPresentation(
          title: 'No hay conexión con el servicio',
          message:
              'No pudimos contactar a Firestore en este momento. Revisá tu conexión e intentá nuevamente.',
        );
      }
    }

    final message = error?.toString() ?? '';
    if (message.contains('SocketException') || message.contains('network')) {
      return const _DashboardErrorPresentation(
        title: 'Parece un problema de red',
        message:
            'No se pudieron descargar las noticias. Revisá tu conexión e intentá nuevamente.',
      );
    }

    return const _DashboardErrorPresentation(
      title: 'No se pudieron cargar las noticias',
      message:
          'Ocurrió un problema al cargar el dashboard. Tocá "Reintentar" para volver a intentar.',
    );
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

class _DashboardErrorPresentation {
  final String title;
  final String message;

  const _DashboardErrorPresentation({
    required this.title,
    required this.message,
  });
}
