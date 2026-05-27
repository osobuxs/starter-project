import 'package:flutter/material.dart';

/// Orange banner shown when the annotator lock is held by someone else.
/// Hidden when [annotatorOwned] is true.
/// [onTakeControl] dispatches AcquireAnnotatorEvent when tapped.
/// For anonymous users [onTakeControl] should be null.
class AnnotatorLockBanner extends StatelessWidget {
  final bool annotatorOwned;
  final String? activeAnnotatorLabel;
  final VoidCallback? onTakeControl;

  const AnnotatorLockBanner({
    Key? key,
    required this.annotatorOwned,
    this.activeAnnotatorLabel,
    this.onTakeControl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (annotatorOwned) return const SizedBox.shrink();

    final labelText = activeAnnotatorLabel != null
        ? '$activeAnnotatorLabel está anotando.'
        : 'Alguien está anotando.';

    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$labelText Tocá para tomar el control.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (onTakeControl != null)
            TextButton(
              onPressed: onTakeControl,
              child: const Text(
                'Tomar control',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
