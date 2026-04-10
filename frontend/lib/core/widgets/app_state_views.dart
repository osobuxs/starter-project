import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  final String? label;
  final EdgeInsetsGeometry padding;

  const AppLoadingState({
    super.key,
    this.label,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (label != null && label!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                label!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppInlineLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const AppInlineLoadingIndicator({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth),
    );
  }
}

class AppCenteredMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final IconData? actionIcon;
  final bool emphasized;

  const AppCenteredMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
    this.actionIcon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(actionIcon ?? Icons.arrow_forward),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: emphasized ? Card(child: content) : content,
      ),
    );
  }
}
