import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';

class RoutePlaceholderPage extends StatelessWidget {
  final String title;
  final String message;
  final String routeName;

  const RoutePlaceholderPage({
    super.key,
    required this.title,
    required this.message,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionScaffold(
      title: title,
      currentRouteName: routeName,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
