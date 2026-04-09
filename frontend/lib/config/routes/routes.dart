import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/route_placeholder_page.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/pages/login/login_page.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/pages/register/register_page.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/pages/user_profile_page.dart';

import '../../features/daily_news/domain/entities/article.dart';
import '../../features/daily_news/presentation/pages/article_detail/article_detail.dart';
import '../../features/daily_news/presentation/pages/home/daily_news.dart';
import '../../features/daily_news/presentation/pages/saved_article/saved_article.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRouteNames.dashboard:
        return _materialRoute(const DailyNews());

      case AppRouteNames.articleDetails:
        return _materialRoute(
          ArticleDetailsView(article: settings.arguments as ArticleEntity),
        );

      case AppRouteNames.savedArticles:
        return _materialRoute(const SavedArticles());

      case AppRouteNames.login:
        return _materialRoute(
          LoginPage(redirectRouteName: settings.arguments as String?),
        );

      case AppRouteNames.register:
        return _materialRoute(
          RegisterPage(redirectRouteName: settings.arguments as String?),
        );

      case AppRouteNames.userProfile:
        return _materialRoute(const UserProfilePage());

      case AppRouteNames.createArticle:
        return _materialRoute(
          const RoutePlaceholderPage(
            title: 'Crear noticia',
            message: 'Esta sección todavía no está implementada.',
            routeName: AppRouteNames.createArticle,
          ),
        );

      case AppRouteNames.myNotes:
        return _materialRoute(
          const RoutePlaceholderPage(
            title: 'Mis notas',
            message: 'Esta sección todavía no está implementada.',
            routeName: AppRouteNames.myNotes,
          ),
        );

      case AppRouteNames.myFavorites:
        return _materialRoute(
          const RoutePlaceholderPage(
            title: 'Mis favoritos',
            message: 'Esta sección todavía no está implementada.',
            routeName: AppRouteNames.myFavorites,
          ),
        );

      default:
        return _materialRoute(const DailyNews());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}
