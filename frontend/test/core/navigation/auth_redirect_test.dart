import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/navigation/auth_redirect.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';

void main() {
  group('resolveAuthRedirectDestination', () {
    test('wraps string route names into redirect destinations', () {
      final destination = resolveAuthRedirectDestination(
        AppRouteNames.myFavorites,
      );

      expect(destination, isNotNull);
      expect(destination?.routeName, AppRouteNames.myFavorites);
      expect(destination?.arguments, isNull);
    });

    test('keeps explicit destination arguments', () {
      const destination = AuthRedirectDestination(
        routeName: AppRouteNames.articleDetails,
        arguments: 'article-123',
      );

      final resolved = resolveAuthRedirectDestination(destination);

      expect(resolved?.routeName, AppRouteNames.articleDetails);
      expect(resolved?.arguments, 'article-123');
    });
  });

  group('resolvePostAuthDestination', () {
    test('falls back to dashboard when redirect is missing', () {
      final destination = resolvePostAuthDestination(null);

      expect(destination.routeName, AppRouteNames.dashboard);
      expect(destination.arguments, isNull);
    });

    test('keeps explicit redirect destinations', () {
      const redirect = AuthRedirectDestination(
        routeName: AppRouteNames.myNotes,
        arguments: 'draft-1',
      );

      final destination = resolvePostAuthDestination(redirect);

      expect(destination.routeName, AppRouteNames.myNotes);
      expect(destination.arguments, 'draft-1');
    });
  });

  group('shouldReplacePostAuthRoot', () {
    test('replaces auth roots and dashboard fallback redirects', () {
      expect(
        shouldReplacePostAuthRoot(
          firstRouteName: AppRouteNames.login,
          destination: const AuthRedirectDestination(
            routeName: AppRouteNames.dashboard,
          ),
        ),
        isTrue,
      );

      expect(
        shouldReplacePostAuthRoot(
          firstRouteName: AppRouteNames.register,
          destination: const AuthRedirectDestination(
            routeName: AppRouteNames.myFavorites,
          ),
        ),
        isTrue,
      );
    });

    test('keeps dashboard as the root for protected redirects', () {
      expect(
        shouldReplacePostAuthRoot(
          firstRouteName: AppRouteNames.dashboard,
          destination: const AuthRedirectDestination(
            routeName: AppRouteNames.myFavorites,
          ),
        ),
        isFalse,
      );
    });
  });

  group('shouldCompleteAuthRedirect', () {
    test('rejects auth screens and dashboard', () {
      expect(
        shouldCompleteAuthRedirect(
          const AuthRedirectDestination(routeName: AppRouteNames.dashboard),
        ),
        isFalse,
      );
      expect(
        shouldCompleteAuthRedirect(
          const AuthRedirectDestination(routeName: AppRouteNames.login),
        ),
        isFalse,
      );
      expect(
        shouldCompleteAuthRedirect(
          const AuthRedirectDestination(routeName: AppRouteNames.register),
        ),
        isFalse,
      );
    });

    test('accepts protected and detail destinations', () {
      expect(
        shouldCompleteAuthRedirect(
          const AuthRedirectDestination(routeName: AppRouteNames.myFavorites),
        ),
        isTrue,
      );
      expect(
        shouldCompleteAuthRedirect(
          const AuthRedirectDestination(
            routeName: AppRouteNames.articleDetails,
          ),
        ),
        isTrue,
      );
    });
  });
}
