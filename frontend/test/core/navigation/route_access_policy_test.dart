import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/navigation/route_access_policy.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';

void main() {
  group('resolveAppRoutePolicy', () {
    test('returns authOnly for login and register', () {
      expect(
        resolveAppRoutePolicy(AppRouteNames.login).requiresAnonymousUser,
        isTrue,
      );
      expect(
        resolveAppRoutePolicy(AppRouteNames.register).requiresAnonymousUser,
        isTrue,
      );
    });

    test('returns protected for profile/authoring/favorites routes', () {
      expect(
        resolveAppRoutePolicy(AppRouteNames.userProfile).requiresAuthentication,
        isTrue,
      );
      expect(
        resolveAppRoutePolicy(
          AppRouteNames.createArticle,
        ).requiresAuthentication,
        isTrue,
      );
      expect(
        resolveAppRoutePolicy(AppRouteNames.myNotes).requiresAuthentication,
        isTrue,
      );
      expect(
        resolveAppRoutePolicy(AppRouteNames.myFavorites).requiresAuthentication,
        isTrue,
      );
    });

    test('returns public for dashboard and detail routes', () {
      expect(
        resolveAppRoutePolicy(AppRouteNames.dashboard).requiresAuthentication,
        isFalse,
      );
      expect(
        resolveAppRoutePolicy(
          AppRouteNames.articleDetails,
        ).requiresAuthentication,
        isFalse,
      );
    });
  });
}
