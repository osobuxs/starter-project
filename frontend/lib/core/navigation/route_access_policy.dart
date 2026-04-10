import 'package:news_app_clean_architecture/core/navigation/route_names.dart';

enum AppRouteAccessPolicy { public, protected, authOnly }

class AppRoutePolicy {
  final AppRouteAccessPolicy access;

  const AppRoutePolicy._(this.access);

  const AppRoutePolicy.public() : this._(AppRouteAccessPolicy.public);

  const AppRoutePolicy.protected() : this._(AppRouteAccessPolicy.protected);

  const AppRoutePolicy.authOnly() : this._(AppRouteAccessPolicy.authOnly);

  bool get requiresAuthentication => access == AppRouteAccessPolicy.protected;

  bool get requiresAnonymousUser => access == AppRouteAccessPolicy.authOnly;
}

AppRoutePolicy resolveAppRoutePolicy(String? routeName) {
  switch (routeName) {
    case AppRouteNames.login:
    case AppRouteNames.register:
      return const AppRoutePolicy.authOnly();
    case AppRouteNames.userProfile:
    case AppRouteNames.createArticle:
    case AppRouteNames.myNotes:
    case AppRouteNames.myFavorites:
      return const AppRoutePolicy.protected();
    case AppRouteNames.dashboard:
    case AppRouteNames.articleDetails:
    default:
      return const AppRoutePolicy.public();
  }
}
