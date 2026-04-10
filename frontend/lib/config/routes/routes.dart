import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/pages/create_edit_article_page.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/pages/my_notes_page.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/pages/login/login_page.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/pages/register/register_page.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/pages/user_profile_page.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

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
        return _materialRoute(LoginPage(redirectRoute: settings.arguments));

      case AppRouteNames.register:
        return _materialRoute(RegisterPage(redirectRoute: settings.arguments));

      case AppRouteNames.userProfile:
        return _materialRoute(const UserProfilePage());

      case AppRouteNames.createArticle:
        final args = settings.arguments as CreateEditArticlePageArgs?;
        return _materialRoute(
          BlocProvider<CreateEditArticleCubit>(
            create: (_) => sl<CreateEditArticleCubit>(),
            child: CreateEditArticlePage(args: args),
          ),
        );

      case AppRouteNames.myNotes:
        return _materialRoute(
          BlocProvider<MyNotesCubit>(
            create: (_) => sl<MyNotesCubit>(),
            child: const MyNotesPage(),
          ),
        );

      case AppRouteNames.myFavorites:
        return _materialRoute(const SavedArticles());

      default:
        return _materialRoute(const DailyNews());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}
