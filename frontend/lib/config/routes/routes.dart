import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/auth_redirect.dart';
import 'package:news_app_clean_architecture/core/navigation/route_access_policy.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_state_views.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/create_edit_article_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/cubit/my_notes_cubit.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/pages/create_edit_article_page.dart';
import 'package:news_app_clean_architecture/features/articles/presentation/pages/my_notes_page.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
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
    final routeName = settings.name ?? AppRouteNames.dashboard;
    final policy = resolveAppRoutePolicy(routeName);

    switch (settings.name) {
      case AppRouteNames.dashboard:
        return _materialRoute(
          settings,
          policy: policy,
          child: const DailyNews(),
        );

      case AppRouteNames.articleDetails:
        final article = settings.arguments is ArticleEntity
            ? settings.arguments as ArticleEntity
            : null;
        return _materialRoute(
          settings,
          policy: policy,
          child: ArticleDetailsView(article: article),
        );

      case AppRouteNames.login:
        return _materialRoute(
          settings,
          policy: policy,
          child: LoginPage(redirectRoute: settings.arguments),
        );

      case AppRouteNames.register:
        return _materialRoute(
          settings,
          policy: policy,
          child: RegisterPage(redirectRoute: settings.arguments),
        );

      case AppRouteNames.userProfile:
        return _materialRoute(
          settings,
          policy: policy,
          child: const UserProfilePage(),
        );

      case AppRouteNames.createArticle:
        final args = settings.arguments as CreateEditArticlePageArgs?;
        return _materialRoute(
          settings,
          policy: policy,
          child: BlocProvider<CreateEditArticleCubit>(
            create: (_) => sl<CreateEditArticleCubit>(),
            child: CreateEditArticlePage(args: args),
          ),
        );

      case AppRouteNames.myNotes:
        return _materialRoute(
          settings,
          policy: policy,
          child: BlocProvider<MyNotesCubit>(
            create: (_) => sl<MyNotesCubit>(),
            child: const MyNotesPage(),
          ),
        );

      case AppRouteNames.myFavorites:
        return _materialRoute(
          settings,
          policy: policy,
          child: const SavedArticles(),
        );

      default:
        return _materialRoute(
          settings,
          policy: policy,
          child: const DailyNews(),
        );
    }
  }

  static Route<dynamic> _materialRoute(
    RouteSettings settings, {
    required AppRoutePolicy policy,
    required Widget child,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) =>
          _RouteAccessGate(settings: settings, policy: policy, child: child),
    );
  }
}

class _RouteAccessGate extends StatefulWidget {
  final RouteSettings settings;
  final AppRoutePolicy policy;
  final Widget child;

  const _RouteAccessGate({
    required this.settings,
    required this.policy,
    required this.child,
  });

  @override
  State<_RouteAccessGate> createState() => _RouteAccessGateState();
}

class _RouteAccessGateState extends State<_RouteAccessGate> {
  bool _redirectScheduled = false;

  bool _shouldHoldProtectedRoute(AuthState authState) {
    return authState is AuthInitial || authState is AuthLoading;
  }

  bool _shouldHoldAnonymousRoute(AuthState authState) {
    return authState is AuthInitial;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (!widget.policy.requiresAuthentication &&
            !widget.policy.requiresAnonymousUser) {
          return widget.child;
        }

        if (widget.policy.requiresAuthentication) {
          if (authState is AuthAuthenticated) {
            _redirectScheduled = false;
            return widget.child;
          }

          if (_shouldHoldProtectedRoute(authState)) {
            return const _RouteRedirectPlaceholder();
          }

          _scheduleProtectedRedirect(context);
          return const _RouteRedirectPlaceholder();
        }

        if (authState is AuthAuthenticated) {
          _scheduleAuthOnlyRedirect(context);
          return const _RouteRedirectPlaceholder();
        }

        if (_shouldHoldAnonymousRoute(authState)) {
          return const _RouteRedirectPlaceholder();
        }

        _redirectScheduled = false;
        return widget.child;
      },
    );
  }

  void _scheduleProtectedRedirect(BuildContext context) {
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;
    final destination = AuthRedirectDestination(
      routeName: widget.settings.name ?? AppRouteNames.dashboard,
      arguments: widget.settings.arguments,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(AppRouteNames.login, arguments: destination);
    });
  }

  void _scheduleAuthOnlyRedirect(BuildContext context) {
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;
    final destination = resolvePostAuthDestination(widget.settings.arguments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(
        destination.routeName,
        arguments: destination.arguments,
      );
    });
  }
}

class _RouteRedirectPlaceholder extends StatelessWidget {
  const _RouteRedirectPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoadingState(label: 'Cargando...'));
  }
}
