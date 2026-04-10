import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';

class AuthRedirectDestination {
  final String routeName;
  final Object? arguments;

  const AuthRedirectDestination({required this.routeName, this.arguments});
}

AuthRedirectDestination? resolveAuthRedirectDestination(Object? rawRedirect) {
  if (rawRedirect is AuthRedirectDestination) {
    return rawRedirect;
  }

  if (rawRedirect is String && rawRedirect.isNotEmpty) {
    return AuthRedirectDestination(routeName: rawRedirect);
  }

  return null;
}

bool shouldCompleteAuthRedirect(AuthRedirectDestination? destination) {
  if (destination == null) {
    return false;
  }

  return destination.routeName.isNotEmpty &&
      destination.routeName != AppRouteNames.dashboard &&
      destination.routeName != AppRouteNames.login &&
      destination.routeName != AppRouteNames.register;
}

void completeAuthRedirect(BuildContext context, Object? redirectRoute) {
  final navigator = Navigator.of(context);
  navigator.popUntil((route) => route.isFirst);

  final destination = resolveAuthRedirectDestination(redirectRoute);
  if (shouldCompleteAuthRedirect(destination)) {
    navigator.pushNamed(
      destination!.routeName,
      arguments: destination.arguments,
    );
  }
}
