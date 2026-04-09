import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';

void completeAuthRedirect(BuildContext context, String? redirectRouteName) {
  final navigator = Navigator.of(context);
  navigator.popUntil((route) => route.isFirst);

  if (redirectRouteName != null &&
      redirectRouteName.isNotEmpty &&
      redirectRouteName != AppRouteNames.dashboard &&
      redirectRouteName != AppRouteNames.login &&
      redirectRouteName != AppRouteNames.register) {
    navigator.pushNamed(redirectRouteName);
  }
}
