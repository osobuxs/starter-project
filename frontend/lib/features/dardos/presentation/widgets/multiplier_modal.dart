import 'package:flutter/material.dart';

/// Bottom sheet that asks the user for a multiplier (1x / 2x / 3x).
/// [number] is the dart number (1-20, 25 for bull).
/// [onSelected] is called with (number, multiplier).
/// For bull (25), only 1x and 2x are available (2x = inner bull = 50).
/// A value of 0 means miss — no modal is shown (handled by caller).
Future<void> showMultiplierModal({
  required BuildContext context,
  required int number,
  required void Function(int number, int multiplier) onSelected,
}) {
  final isBull = number == 25;

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBull ? 'Bull' : '$number',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _MultiplierButton(
                      label: '1x',
                      value: '${number * 1}',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelected(number, 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MultiplierButton(
                      label: '2x',
                      value: isBull ? 'Bull 50' : '${number * 2}',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelected(number, 2);
                      },
                    ),
                  ),
                  if (!isBull) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MultiplierButton(
                        label: '3x',
                        value: '${number * 3}',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onSelected(number, 3);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MultiplierButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _MultiplierButton({
    Key? key,
    required this.label,
    required this.value,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
