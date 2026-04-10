import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_dialogs.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';

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

AuthRedirectDestination resolvePostAuthDestination(Object? rawRedirect) {
  final destination = resolveAuthRedirectDestination(rawRedirect);
  if (shouldCompleteAuthRedirect(destination)) {
    return destination!;
  }

  return const AuthRedirectDestination(routeName: AppRouteNames.dashboard);
}

void redirectToLogin(
  BuildContext context, {
  required String currentRouteName,
  required AuthRedirectDestination destination,
}) {
  final shouldReplaceCurrent =
      currentRouteName == AppRouteNames.login ||
      currentRouteName == AppRouteNames.register;

  if (shouldReplaceCurrent) {
    Navigator.of(
      context,
    ).pushReplacementNamed(AppRouteNames.login, arguments: destination);
    return;
  }

  Navigator.of(context).pushNamed(AppRouteNames.login, arguments: destination);
}

Future<void> navigateRequiringAuthentication(
  BuildContext context, {
  required BuildContext navigationContext,
  required String currentRouteName,
  required AuthRedirectDestination destination,
  required String actionLabel,
  String successMessage = 'Después te llevamos automáticamente.',
  bool closeCurrentNavigator = false,
}) async {
  final authState = context.read<AuthCubit>().state;
  if (authState is AuthAuthenticated) {
    Navigator.of(
      navigationContext,
    ).pushNamed(destination.routeName, arguments: destination.arguments);
    return;
  }

  if (closeCurrentNavigator) {
    Navigator.of(context).pop();
  }

  final shouldContinue = await showAuthenticationRequiredDialog(
    navigationContext,
    actionLabel: actionLabel,
    successMessage: successMessage,
  );

  if (shouldContinue != true || !navigationContext.mounted) {
    return;
  }

  redirectToLogin(
    navigationContext,
    currentRouteName: currentRouteName,
    destination: destination,
  );
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
