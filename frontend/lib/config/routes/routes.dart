import 'package:flutter/material.dart';
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
      case '/':
        return _materialRoute(const DailyNews());

      case '/ArticleDetails':
        return _materialRoute(
          ArticleDetailsView(article: settings.arguments as ArticleEntity),
        );

      case '/SavedArticles':
        return _materialRoute(const SavedArticles());

      case '/Login':
        return _materialRoute(const LoginPage());

      case '/Register':
        return _materialRoute(const RegisterPage());

      case '/UserProfile':
        return _materialRoute(const UserProfilePage());

      default:
        return _materialRoute(const DailyNews());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}
