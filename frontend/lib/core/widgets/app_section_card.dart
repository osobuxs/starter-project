import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: clipBehavior,
      child: Padding(padding: padding, child: child),
    );
  }
}
